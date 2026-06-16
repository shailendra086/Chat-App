import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  String get myId => _authController.user?.uid ?? '';

  late final String chatId;
  late final UserModel peerUser;
  final Rx<UserModel?> peerUserStream = Rx<UserModel?>(null);

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxList<MessageModel> filteredMessages = <MessageModel>[].obs;
  
  final Rx<MessageModel?> replyingToMessage = Rx<MessageModel?>(null);
  final RxString searchQuery = "".obs;
  final RxBool isSearching = false.obs;

  final TextEditingController messageFieldController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      chatId = args['chatId'] as String;
      peerUser = args['peerUser'] as UserModel;
      peerUserStream.value = peerUser;

      _listenToPeerStatus();
      _loadMessages();
      _setupSearchFilter();
    } else {
      print("Warning: ChatController initialized with null or invalid arguments.");
      chatId = '';
      peerUser = UserModel(
        id: '',
        email: '',
        displayName: '',
        photoURL: '',
        isOnline: false,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );
      peerUserStream.value = peerUser;
    }
  }

  @override
  void onClose() {
    messageFieldController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _listenToPeerStatus() {
    _firestoreService.getUserStream(peerUser.id).listen((user) {
      if (user != null) {
        peerUserStream.value = user;
      }
    });
  }

  void _setupSearchFilter() {
    ever(messages, (_) => _filterMessages());
    ever(searchQuery, (_) => _filterMessages());
    ever(isSearching, (_) => _filterMessages());
  }

  void _filterMessages() {
    if (!isSearching.value || searchQuery.isEmpty) {
      filteredMessages.value = messages;
    } else {
      final query = searchQuery.value.toLowerCase().trim();
      filteredMessages.value = messages
          .where((msg) => msg.content.toLowerCase().contains(query))
          .toList();
    }
  }

  void _loadMessages() {
    final myId = _authController.user?.uid;
    if (myId != null) {
      isLoading.value = true;
      messages.bindStream(_firestoreService.getMessages(chatId));

      ever(messages, (_) {
        _firestoreService.markMessagesAsRead(chatId, myId);
      });

      messages.listen((list) {
        isLoading.value = false;
        _filterMessages();
      }, onError: (_) {
        isLoading.value = false;
      });
    }
  }

  void setReplyingTo(MessageModel? message) {
    replyingToMessage.value = message;
  }

  Future<void> reactToMessage(MessageModel message, String emoji) async {
    try {
      await _firestoreService.updateMessageReaction(chatId, message.id, myId, emoji);
    } catch (e) {
      Get.snackbar("Error", "Failed to react: ${e.toString()}");
    }
  }

  Future<void> togglePinMessage(MessageModel message) async {
    try {
      final newPinnedStatus = !message.isPinned;
      await _firestoreService.togglePinMessage(chatId, message.id, newPinnedStatus);
      Get.snackbar("Success", newPinnedStatus ? "Message pinned!" : "Message unpinned!");
    } catch (e) {
      Get.snackbar("Error", "Failed to pin message: ${e.toString()}");
    }
  }

  Future<void> forwardMessage(MessageModel message, String targetPeerId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final targetChatId = await _firestoreService.getOrCreateChat(myId, targetPeerId);

      final forwardedMsg = MessageModel(
        id: '',
        senderId: myId,
        receiverId: targetPeerId,
        content: message.content,
        timestamp: DateTime.now(),
        isRead: false,
        isForwarded: true,
      );

      await _firestoreService.sendMessage(targetChatId, forwardedMsg);

      Get.back(); // Dismiss loader
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar("Success", "Message forwarded successfully!");
      });
    } catch (e) {
      Get.back();
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar("Error", "Failed to forward message: ${e.toString()}");
      });
    }
  }

  Future<void> clearChatHistory() async {
    try {
      Get.dialog(
        AlertDialog(
          title: const Text("Clear History"),
          content: const Text("Are you sure you want to clear this chat's history? This deletes the messages for both users and cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Get.back(); // Close dialog
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );
                await _firestoreService.clearChatHistory(chatId);
                Get.back(); // Close progress indicator
                Future.delayed(const Duration(milliseconds: 100), () {
                  Get.snackbar("Success", "Chat history cleared!");
                });
              },
              child: const Text("Clear", style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      );
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar("Error", "Failed to clear history: ${e.toString()}");
      });
    }
  }

  Future<void> sendMessage() async {
    final content = messageFieldController.text.trim();
    if (content.isEmpty) return;

    final myId = _authController.user?.uid;
    if (myId == null) return;

    try {
      isSending.value = true;
      messageFieldController.clear();

      final replyTarget = replyingToMessage.value;
      replyingToMessage.value = null; // Reset replyingTo target

      final newMessage = MessageModel(
        id: '',
        senderId: myId,
        receiverId: peerUser.id,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        replyToId: replyTarget?.id,
        replyToContent: replyTarget?.content,
        replyToSenderId: replyTarget?.senderId,
      );

      await _firestoreService.sendMessage(chatId, newMessage);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send message: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }
}
