import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/friend_request_controller.dart';
import 'package:chat_app/controllers/user_list_controller.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/views/friend_request_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserListController>();
    final requestController = Get.find<FriendRequestController>();
    final myId = Get.find<AuthController>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 1. Premium Search Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFF8C7AE6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Find Friends",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    
                    // Friend Requests Icon Button (Upper Right Side)
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Get.bottomSheet(
                              const FriendRequestSheet(),
                              isScrollControlled: true,
                              ignoreSafeArea: false,
                            );
                          },
                          icon: const Icon(
                            Icons.group_add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Obx(() {
                          final count = requestController.incomingRequests.length;
                          if (count == 0) return const SizedBox.shrink();

                          return Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$count',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: controller.updateSearch,
                  onSubmitted: (_) => controller.searchUserByEmail(),
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: "Enter friend's exact email...",
                    hintStyle: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                      onPressed: controller.searchUserByEmail,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Results / Placeholder
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              }

              final user = controller.searchedUser.value;
              if (user == null) {
                return _buildSearchPlaceholder(context);
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: _buildUserResultCard(context, user, myId),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPlaceholder(BuildContext context) {
    final requestController = Get.find<FriendRequestController>();
    final myId = Get.find<AuthController>().user?.uid ?? '';

    return Obx(() {
      final incoming = requestController.incomingRequests;
      final outgoing = requestController.outgoingRequests;
      final accepted = requestController.acceptedRequests;

      if (incoming.isEmpty && outgoing.isEmpty && accepted.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Search for Friends",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your friend's exact email address in the search bar above to send a friend request.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Pending Requests Section
          if (incoming.isNotEmpty || outgoing.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                "Pending Requests",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
              ),
            ),
            ...incoming.map((req) => _buildIncomingRequestCard(context, req, requestController)),
            ...outgoing.map((req) => _buildOutgoingRequestCard(context, req)),
            const SizedBox(height: 24),
          ],

          // 2. My Friends Section
          if (accepted.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                "My Friends (${accepted.length})",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: accepted.length,
              itemBuilder: (context, index) {
                final req = accepted[index];
                return _buildFriendCard(context, req, myId);
              },
            ),
          ],
        ],
      );
    });
  }

  Widget _buildIncomingRequestCard(
      BuildContext context, Map<String, dynamic> req, FriendRequestController controller) {
    final senderId = req['senderId'] as String? ?? '';
    final name = req['senderName'] as String? ?? 'Unknown User';
    final email = req['senderEmail'] as String? ?? '';
    final photoURL = req['senderPhotoURL'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
            child: photoURL.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    fontSize: 15,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => controller.declineRequest(senderId),
                icon: const Icon(Icons.close_rounded, color: AppTheme.errorColor),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => controller.acceptRequest(senderId),
                icon: const Icon(Icons.check_rounded, color: AppTheme.successColor),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.successColor.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingRequestCard(BuildContext context, Map<String, dynamic> req) {
    final name = req['receiverName'] as String? ?? 'Unknown User';
    final email = req['receiverEmail'] as String? ?? '';
    final photoURL = req['receiverPhotoURL'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
            child: photoURL.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    fontSize: 15,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Requested",
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, Map<String, dynamic> req, String myId) {
    final isSender = req['senderId'] == myId;
    final peerId = isSender ? req['receiverId'] as String? ?? '' : req['senderId'] as String? ?? '';
    final name = isSender ? req['receiverName'] as String? ?? 'Unknown Friend' : req['senderName'] as String? ?? 'Unknown Friend';
    final email = isSender ? req['receiverEmail'] as String? ?? '' : req['senderEmail'] as String? ?? '';
    final photoURL = isSender ? req['receiverPhotoURL'] as String? ?? '' : req['senderPhotoURL'] as String? ?? '';

    final peerUser = UserModel(
      id: peerId,
      displayName: name,
      email: email,
      photoURL: photoURL,
      isOnline: false,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
            child: photoURL.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    fontSize: 15,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              final ids = [myId, peerId]..sort();
              final chatId = ids.join('_');
              Get.toNamed(
                AppRoutes.chat,
                arguments: {'chatId': chatId, 'peerUser': peerUser},
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.chat_bubble_rounded, size: 14),
            label: const Text("Chat"),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResultCard(BuildContext context, UserModel user, String myId) {
    final controller = Get.find<UserListController>();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Large profile avatar
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor,
                    child: user.photoURL.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              user.photoURL,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                  ),
                ),
              ),
              if (user.isOnline)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    height: 18,
                    width: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Name and email
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 24),

          // Friend Status Button
          Obx(() {
            final status = controller.friendshipStatus.value;
            
            if (status == 'accepted') {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final ids = [myId, user.id]..sort();
                    final chatId = ids.join('_');
                    Get.toNamed(
                      AppRoutes.chat,
                      arguments: {'chatId': chatId, 'peerUser': user},
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text("Send Message"),
                ),
              );
            }

            if (status == 'pending_sent') {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey,
                  ),
                  icon: const Icon(Icons.hourglass_empty_rounded),
                  label: const Text("Request Sent"),
                ),
              );
            }

            if (status == 'pending_received') {
              return Column(
                children: [
                  const Text(
                    "This user has sent you a friend request!",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.declineRequestDirectly,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.errorColor),
                            foregroundColor: AppTheme.errorColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text("Decline"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.acceptRequestDirectly,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text("Accept"),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            // 'none' friendship status
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.sendRequest,
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                ),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text("Add Friend"),
              ),
            );
          }),
        ],
      ),
    );
  }
}
