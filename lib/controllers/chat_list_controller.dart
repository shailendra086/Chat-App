import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:get/get.dart';

class ChatListController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ChatModel> activeChats = <ChatModel>[].obs;
  final RxMap<String, UserModel> peerUsers = <String, UserModel>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (_authController.user != null) {
      _loadActiveChats(_authController.user!.uid);
    }
    ever(_authController.rxUser, (user) {
      if (user != null) {
        _loadActiveChats(user.uid);
      } else {
        activeChats.clear();
      }
    });
  }

  void _loadActiveChats(String myId) {
    isLoading.value = true;
    activeChats.bindStream(_firestoreService.getActiveChats(myId));
    
    ever(activeChats, (List<ChatModel> chats) {
      for (var chat in chats) {
        final peerId = chat.getPeerId(myId);
        if (peerId.isNotEmpty && !peerUsers.containsKey(peerId)) {
          _listenToPeer(peerId);
        }
      }
    });

    activeChats.listen((_) {
      isLoading.value = false;
    }, onError: (err) {
      isLoading.value = false;
      print("Error loading active chats: $err");
    });
  }

  Future<void> refreshChats() async {
    final myId = _authController.user?.uid;
    if (myId != null) {
      _loadActiveChats(myId);
      // Wait a short time to show smooth spinner animation
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  void _listenToPeer(String peerId) {
    _firestoreService.getUserStream(peerId).listen((user) {
      if (user != null) {
        peerUsers[peerId] = user;
      }
    });
  }

  UserModel? getPeerUser(String peerId) {
    return peerUsers[peerId];
  }
}
