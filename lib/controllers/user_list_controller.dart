import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:get/get.dart';

class UserListController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final Rx<UserModel?> searchedUser = Rx<UserModel?>(null);
  final RxString friendshipStatus = 'none'.obs; // 'none', 'pending_sent', 'pending_received', 'accepted'
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  UserModel? myProfile;

  @override
  void onInit() {
    super.onInit();
    if (_authController.user != null) {
      _loadMyProfile(_authController.user!.uid);
    }
    ever(_authController.rxUser, (user) {
      if (user != null) {
        _loadMyProfile(user.uid);
      } else {
        myProfile = null;
      }
    });
  }

  Future<void> _loadMyProfile(String myId) async {
    try {
      myProfile = await _firestoreService.getUser(myId);
    } catch (e) {
      print("Error loading my profile: $e");
    }
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      searchedUser.value = null;
    }
  }

  Future<void> searchUserByEmail() async {
    final email = searchQuery.value.trim();
    if (email.isEmpty) return;

    if (!GetUtils.isEmail(email)) {
      Get.snackbar("Invalid Email", "Please enter a valid email address.");
      searchedUser.value = null;
      return;
    }

    final myId = _authController.user?.uid;
    if (myId == null) return;

    if (myProfile == null) {
      await _loadMyProfile(myId);
    }

    if (myProfile != null && myProfile!.email.toLowerCase() == email.toLowerCase()) {
      Get.snackbar("Info", "You cannot search or add yourself.");
      searchedUser.value = null;
      return;
    }

    try {
      isLoading.value = true;
      searchedUser.value = null;

      final user = await _firestoreService.getUserByEmail(email);
      if (user != null) {
        searchedUser.value = user;
        final status = await _firestoreService.getFriendshipStatus(myId, user.id);
        friendshipStatus.value = status;
      } else {
        Get.snackbar("Not Found", "No user registered with this email.");
      }
    } catch (e) {
      Get.snackbar("Error", "Search failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendRequest() async {
    final receiver = searchedUser.value;
    if (receiver == null || myProfile == null) return;

    try {
      isLoading.value = true;
      await _firestoreService.sendFriendRequest(myProfile!, receiver);
      friendshipStatus.value = 'pending_sent';
      Get.snackbar("Success", "Friend request sent to ${receiver.displayName}");
    } catch (e) {
      Get.snackbar("Error", "Failed to send request: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptRequestDirectly() async {
    final sender = searchedUser.value;
    final myId = _authController.user?.uid;
    if (sender == null || myId == null) return;

    try {
      isLoading.value = true;
      await _firestoreService.acceptFriendRequest(sender.id, myId);
      friendshipStatus.value = 'accepted';
      Get.snackbar("Success", "You are now friends with ${sender.displayName}!");
    } catch (e) {
      Get.snackbar("Error", "Failed to accept request: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> declineRequestDirectly() async {
    final sender = searchedUser.value;
    final myId = _authController.user?.uid;
    if (sender == null || myId == null) return;

    try {
      isLoading.value = true;
      await _firestoreService.declineFriendRequest(sender.id, myId);
      friendshipStatus.value = 'none';
      Get.snackbar("Info", "Friend request declined.");
    } catch (e) {
      Get.snackbar("Error", "Failed to decline request: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }
}
