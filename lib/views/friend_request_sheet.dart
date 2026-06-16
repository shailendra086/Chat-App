import 'package:chat_app/controllers/friend_request_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendRequestSheet extends StatelessWidget {
  const FriendRequestSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FriendRequestController>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Friend Requests",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Obx(() => Text(
                      "${controller.incomingRequests.length} pending",
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderColor),

          // Request List
          Flexible(
            child: Obx(() {
              if (controller.isLoading.value && controller.incomingRequests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                );
              }

              if (controller.incomingRequests.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.incomingRequests.length,
                itemBuilder: (context, index) {
                  final request = controller.incomingRequests[index];
                  final senderId = request['senderId'] ?? '';
                  final senderName = request['senderName'] ?? 'Unknown User';
                  final senderEmail = request['senderEmail'] ?? '';
                  final senderPhoto = request['senderPhotoURL'] ?? '';

                  return _buildRequestTile(
                    context,
                    controller,
                    senderId,
                    senderName,
                    senderEmail,
                    senderPhoto,
                  );
                },
              );
            }),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No pending requests",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "When someone sends you a friend request, it will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    FriendRequestController controller,
    String senderId,
    String senderName,
    String senderEmail,
    String senderPhoto,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primaryColor,
              child: senderPhoto.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        senderPhoto,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    senderEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => controller.declineRequest(senderId),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.errorColor),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => controller.acceptRequest(senderId),
                  icon: const Icon(Icons.check_rounded, color: AppTheme.successColor),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.successColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
