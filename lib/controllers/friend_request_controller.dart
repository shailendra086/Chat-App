import 'dart:async';
import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendRequestController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> incomingRequests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> outgoingRequests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> acceptedRequests = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;
  StreamSubscription? _sentAcceptedSub;
  StreamSubscription? _receivedAcceptedSub;

  List<Map<String, dynamic>> _sentAcceptedList = [];
  List<Map<String, dynamic>> _receivedAcceptedList = [];

  final Set<String> _notifiedRequestIds = {};
  bool _isInitialSentAccepted = true;

  @override
  void onInit() {
    super.onInit();
    if (_authController.user != null) {
      _listenToStreams(_authController.user!.uid);
    }
    ever(_authController.rxUser, (user) {
      if (user != null) {
        _listenToStreams(user.uid);
      } else {
        _clearStreams();
      }
    });
  }

  @override
  void onClose() {
    _clearStreams();
    super.onClose();
  }

  void _clearStreams() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _sentAcceptedSub?.cancel();
    _receivedAcceptedSub?.cancel();
    incomingRequests.clear();
    outgoingRequests.clear();
    acceptedRequests.clear();
    _sentAcceptedList.clear();
    _receivedAcceptedList.clear();
    _notifiedRequestIds.clear();
    _isInitialSentAccepted = true;
  }

  void _listenToStreams(String myId) {
    _clearStreams();
    isLoading.value = true;

    // Incoming requests stream
    _incomingSub = _firestoreService.getIncomingRequestsStream(myId).listen((list) {
      incomingRequests.value = list;
      isLoading.value = false;
    }, onError: (err) {
      isLoading.value = false;
      print("Error loading incoming requests: $err");
    });

    // Outgoing requests stream
    _outgoingSub = _firestoreService.getOutgoingRequestsStream(myId).listen((list) {
      outgoingRequests.value = list;
    }, onError: (err) {
      print("Error loading outgoing requests: $err");
    });

    // Sent accepted stream (for notifications when my request is accepted)
    _sentAcceptedSub = _firestoreService.getSentAcceptedStream(myId).listen((list) {
      _sentAcceptedList = list;
      _updateAcceptedRequests();

      if (_isInitialSentAccepted) {
        for (var req in list) {
          final reqId = req['id'] as String?;
          if (reqId != null) {
            _notifiedRequestIds.add(reqId);
          }
        }
        _isInitialSentAccepted = false;
      } else {
        for (var req in list) {
          final reqId = req['id'] as String?;
          final receiverName = req['receiverName'] as String? ?? 'Someone';
          if (reqId != null && !_notifiedRequestIds.contains(reqId)) {
            _notifiedRequestIds.add(reqId);
            // Trigger snackbar notification
            Get.snackbar(
              "Friend Request Accepted",
              "$receiverName accepted your friend request!",
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppTheme.successColor.withOpacity(0.9),
              colorText: Colors.white,
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              duration: const Duration(seconds: 4),
            );
          }
        }
      }
    }, onError: (err) {
      print("Error loading sent accepted requests: $err");
    });

    // Received accepted stream
    _receivedAcceptedSub = _firestoreService.getReceivedAcceptedStream(myId).listen((list) {
      _receivedAcceptedList = list;
      _updateAcceptedRequests();
    }, onError: (err) {
      print("Error loading received accepted requests: $err");
    });
  }

  void _updateAcceptedRequests() {
    final combined = [..._sentAcceptedList, ..._receivedAcceptedList];
    // Sort by timestamp if available
    combined.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime); // descending order (newest first)
    });
    acceptedRequests.value = combined;
  }

  Future<void> acceptRequest(String senderId) async {
    final myId = _authController.user?.uid;
    if (myId == null) return;

    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      await _firestoreService.acceptFriendRequest(senderId, myId);
      Get.back(); // Dismiss loading spinner
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar("Success", "Friend request accepted!");
      });
    } catch (e) {
      Get.back();
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar("Error", "Failed to accept request: ${e.toString()}");
      });
    }
  }

  Future<void> declineRequest(String senderId) async {
    final myId = _authController.user?.uid;
    if (myId == null) return;

    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      await _firestoreService.declineFriendRequest(senderId, myId);
      Get.back(); // Dismiss loading spinner
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar("Info", "Friend request declined.");
      });
    } catch (e) {
      Get.back();
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar("Error", "Failed to decline request: ${e.toString()}");
      });
    }
  }
}
