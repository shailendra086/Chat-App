import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception("Failed to create user: ${e.toString()}");
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot? doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get user: ${e.toString()}");
    }
  }

  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      throw Exception("Failed to update user online status: ${e.toString()}");
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception("Failed to delete user: ${e.toString()}");
    }
  }

  Stream<UserModel?> getUserStream(String userId)  {
   
      return _firestore.collection('users').doc(userId).snapshots().map((doc)=>doc.exists?UserModel.fromMap(doc.data()!):null);
    
    
  }

  Future<void>updateUser(UserModel user)async{
      try{
          await _firestore.collection('users').doc(user.id).update(user.toMap());
      }catch(e){
        throw Exception("Failed to update user: ${e.toString()}");
      }
  }

  Stream<List<UserModel>> getUsersExceptMe(String myId) {
    return _firestore
        .collection('users')
        .where('id', isNotEqualTo: myId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  Future<String> getOrCreateChat(String myId, String peerId) async {
    final ids = [myId, peerId]..sort();
    final chatId = ids.join('_');

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      final newChat = ChatModel(
        id: chatId,
        participants: [myId, peerId],
        unreadCounts: {myId: 0, peerId: 0},
      );
      await _firestore.collection('chats').doc(chatId).set(newChat.toMap());
    }
    return chatId;
  }

  Stream<List<ChatModel>> getActiveChats(String myId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: myId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .toList();
          chats.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });
          return chats;
        });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    try {
      final messageDoc = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final messageWithId = message.copyWith(id: messageDoc.id);

      final batch = _firestore.batch();
      batch.set(messageDoc, messageWithId.toMap());

      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnapshot = await chatRef.get();
      
      Map<String, dynamic> updates = {
        'lastMessage': message.content,
        'lastMessageSenderId': message.senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };

      if (chatSnapshot.exists) {
        final chatData = chatSnapshot.data() as Map<String, dynamic>;
        final unreadCounts = Map<String, int>.from(chatData['unreadCounts'] ?? {});
        final receiverId = message.receiverId;
        unreadCounts[receiverId] = (unreadCounts[receiverId] ?? 0) + 1;
        updates['unreadCounts'] = unreadCounts;
      }

      batch.update(chatRef, updates);
      await batch.commit();
    } catch (e) {
      throw Exception("Failed to send message: ${e.toString()}");
    }
  }

  Future<void> markMessagesAsRead(String chatId, String myId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) return;

      final chatData = chatSnapshot.data() as Map<String, dynamic>;
      final unreadCounts = Map<String, int>.from(chatData['unreadCounts'] ?? {});
      
      unreadCounts[myId] = 0;

      final batch = _firestore.batch();
      batch.update(chatRef, {'unreadCounts': unreadCounts});

      final unreadMessagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: myId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print("Failed to mark messages as read: $e");
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception("Failed to look up user: ${e.toString()}");
    }
  }

  Future<void> sendFriendRequest(UserModel sender, UserModel receiver) async {
    try {
      final requestId = "${sender.id}_${receiver.id}";
      await _firestore.collection('friend_requests').doc(requestId).set({
        'id': requestId,
        'senderId': sender.id,
        'receiverId': receiver.id,
        'status': 'pending',
        'senderName': sender.displayName,
        'senderEmail': sender.email,
        'senderPhotoURL': sender.photoURL,
        'receiverName': receiver.displayName,
        'receiverEmail': receiver.email,
        'receiverPhotoURL': receiver.photoURL,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to send friend request: ${e.toString()}");
    }
  }

  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream(String myId) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: myId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> acceptFriendRequest(String senderId, String receiverId) async {
    try {
      final requestId = "${senderId}_${receiverId}";
      final batch = _firestore.batch();

      final requestRef = _firestore.collection('friend_requests').doc(requestId);
      batch.update(requestRef, {'status': 'accepted'});

      final ids = [senderId, receiverId]..sort();
      final chatId = ids.join('_');
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      batch.set(chatRef, {
        'id': chatId,
        'participants': [senderId, receiverId],
        'lastMessage': 'You are now friends! Start chatting.',
        'lastMessageSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {senderId: 0, receiverId: 0},
      });

      await batch.commit();
    } catch (e) {
      throw Exception("Failed to accept friend request: ${e.toString()}");
    }
  }

  Future<void> declineFriendRequest(String senderId, String receiverId) async {
    try {
      final requestId = "${senderId}_${receiverId}";
      await _firestore.collection('friend_requests').doc(requestId).delete();
    } catch (e) {
      throw Exception("Failed to decline friend request: ${e.toString()}");
    }
  }

  Future<String> getFriendshipStatus(String myId, String peerId) async {
    try {
      final sentId = "${myId}_${peerId}";
      final sentDoc = await _firestore.collection('friend_requests').doc(sentId).get();
      if (sentDoc.exists) {
        final data = sentDoc.data();
        if (data != null && data['status'] == 'accepted') return 'accepted';
        return 'pending_sent';
      }

      final receivedId = "${peerId}_${myId}";
      final receivedDoc = await _firestore.collection('friend_requests').doc(receivedId).get();
      if (receivedDoc.exists) {
        final data = receivedDoc.data();
        if (data != null && data['status'] == 'accepted') return 'accepted';
        return 'pending_received';
      }

      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  Stream<List<Map<String, dynamic>>> getOutgoingRequestsStream(String myId) {
    return _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: myId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getSentAcceptedStream(String myId) {
    return _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: myId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getReceivedAcceptedStream(String myId) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: myId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> clearChatHistory(String chatId) async {
    try {
      final messagesRef = _firestore.collection('chats').doc(chatId).collection('messages');
      final querySnapshot = await messagesRef.get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': 'Chat history cleared',
        'lastMessageSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      final chatSnap = await chatRef.get();
      if (chatSnap.exists) {
        final chatData = chatSnap.data() as Map<String, dynamic>;
        final unreadCounts = Map<String, int>.from(chatData['unreadCounts'] ?? {});
        unreadCounts.forEach((key, value) {
          unreadCounts[key] = 0;
        });
        batch.update(chatRef, {'unreadCounts': unreadCounts});
      }

      await batch.commit();
    } catch (e) {
      throw Exception("Failed to clear chat history: ${e.toString()}");
    }
  }

  Future<void> updateMessageReaction(
      String chatId, String messageId, String userId, String emoji) async {
    try {
      final docRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final data = snapshot.data();
          final reactions = Map<String, String>.from(data?['reactions'] ?? {});
          if (reactions[userId] == emoji) {
            reactions.remove(userId);
          } else {
            reactions[userId] = emoji;
          }
          transaction.update(docRef, {'reactions': reactions});
        }
      });
    } catch (e) {
      throw Exception("Failed to update reaction: ${e.toString()}");
    }
  }

  Future<void> togglePinMessage(String chatId, String messageId, bool isPinned) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': isPinned});
    } catch (e) {
      throw Exception("Failed to toggle pin status: ${e.toString()}");
    }
  }
}
