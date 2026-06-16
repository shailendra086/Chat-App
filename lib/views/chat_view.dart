import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/controllers/friend_request_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        centerTitle: false,
        leading: Obx(() {
          if (controller.isSearching.value) {
            return IconButton(
              onPressed: () {
                controller.isSearching.value = false;
                controller.searchQuery.value = '';
              },
              icon: const Icon(
                Icons.close_rounded,
                color: AppTheme.textPrimaryColor,
              ),
            );
          }
          return IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimaryColor,
            ),
          );
        }),
        title: Obx(() {
          if (controller.isSearching.value) {
            return TextField(
              autofocus: true,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: "Search messages...",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => controller.searchQuery.value = val,
            );
          }

          final peer = controller.peerUserStream.value;
          if (peer == null) return const SizedBox.shrink();

          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor,
                child: peer.photoURL.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          peer.photoURL,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        peer.displayName.isNotEmpty
                            ? peer.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (peer.isOnline) ...[
                          Container(
                            height: 6,
                            width: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          peer.isOnline ? "Online" : "Offline",
                          style: TextStyle(
                            fontSize: 11,
                            color: peer.isOnline
                                ? AppTheme.successColor
                                : AppTheme.textSecondaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        actions: [
          Obx(() {
            if (controller.isSearching.value) return const SizedBox.shrink();
            return IconButton(
              onPressed: () => controller.isSearching.value = true,
              icon: const Icon(
                Icons.search_rounded,
                color: AppTheme.textPrimaryColor,
              ),
            );
          }),
          Obx(() {
            if (controller.isSearching.value) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppTheme.textPrimaryColor,
              ),
              onSelected: (val) {
                if (val == 'clear') {
                  controller.clearChatHistory();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Text("Clear History"),
                ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Pinned Message Banner
          Obx(() {
            final pins = controller.messages.where((m) => m.isPinned).toList();
            if (pins.isEmpty) return const SizedBox.shrink();

            return Container(
              color: AppTheme.primaryColor.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.push_pin_rounded,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Pinned: ${pins.first.content}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final index = controller.filteredMessages.indexOf(
                        pins.first,
                      );
                      if (index != -1) {
                        controller.scrollController.animateTo(
                          index * 72.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: const Text(
                      "View",
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // 1. Messages Feed
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.filteredMessages.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );
              }

              if (controller.filteredMessages.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                controller: controller.scrollController,
                reverse: true, // Newer messages at the bottom
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.filteredMessages.length,
                itemBuilder: (context, index) {
                  final message = controller.filteredMessages[index];
                  final isMe = message.senderId == controller.myId;
                  return GestureDetector(
                    onLongPress: () => _showMessageOptions(context, message),
                    child: _buildMessageBubble(context, message, isMe),
                  );
                },
              );
            }),
          ),

          // Reply Preview Bar
          Obx(() {
            final replyMsg = controller.replyingToMessage.value;
            if (replyMsg == null) return const SizedBox.shrink();

            final isMe = replyMsg.senderId == controller.myId;
            final senderName = isMe ? "You" : controller.peerUser.displayName;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                  bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          replyMsg.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: () => controller.setReplyingTo(null),
                  ),
                ],
              ),
            );
          }),

          // 2. Message Composer
          _buildMessageComposer(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Say Hi to ${controller.peerUserStream.value?.displayName ?? ''}!",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Send a message to start a conversation.",
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MessageModel message,
    bool isMe,
  ) {
    final formattedTime = _formatTime(message.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe
                    ? const Radius.circular(16)
                    : const Radius.circular(0),
                bottomRight: isMe
                    ? const Radius.circular(0)
                    : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Forwarded tag
                if (message.isForwarded) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        size: 12,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Forwarded",
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Reply metadata block
                if (message.replyToId != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.black.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isMe ? Colors.white70 : AppTheme.primaryColor,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.replyToSenderId == controller.myId
                              ? "You"
                              : controller.peerUser.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isMe ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message.replyToContent ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe
                                ? Colors.white.withOpacity(0.8)
                                : AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Content
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimaryColor,
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Footer row
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isPinned) ...[
                        Icon(
                          Icons.push_pin_rounded,
                          size: 12,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : AppTheme.textSecondaryColor.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: message.isRead
                              ? const Color(0xFF55EFC4)
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reactions Chip
          if (message.reactions.isNotEmpty) _buildReactionsChip(message),
        ],
      ),
    );
  }

  Widget _buildReactionsChip(MessageModel message) {
    final counts = <String, int>{};
    message.reactions.values.forEach((emoji) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    });

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 4, left: 12, right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: counts.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: Text(
              "${entry.key}${entry.value > 1 ? ' ${entry.value}' : ''}",
              style: const TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, MessageModel message) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reactions Picker Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '😂', '👍', '😮', '😢', '🙏'].map((emoji) {
                final hasReacted = message.reactions[controller.myId] == emoji;
                return InkWell(
                  onTap: () {
                    Get.back();
                    controller.reactToMessage(message, emoji);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasReacted
                          ? AppTheme.primaryColor.withOpacity(0.15)
                          : Colors.transparent,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 8),

            // Actions Menu
            ListTile(
              leading: const Icon(
                Icons.reply_rounded,
                color: AppTheme.primaryColor,
              ),
              title: const Text("Reply"),
              onTap: () {
                Get.back();
                controller.setReplyingTo(message);
              },
            ),
            ListTile(
              leading: Icon(
                message.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.pin_drop_rounded,
                color: AppTheme.primaryColor,
              ),
              title: Text(message.isPinned ? "Unpin Message" : "Pin Message"),
              onTap: () {
                Get.back();
                controller.togglePinMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.forward_rounded,
                color: AppTheme.primaryColor,
              ),
              title: const Text("Forward Message"),
              onTap: () {
                Get.back();
                _showForwardSelectionSheet(context, message);
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showForwardSelectionSheet(BuildContext context, MessageModel message) {
    final friendController = Get.find<FriendRequestController>();
    final myId = controller.myId;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Forward to...",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final friends = friendController.acceptedRequests;
              if (friends.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "No friends available to forward.",
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final req = friends[index];
                    final isSender = req['senderId'] == myId;
                    final peerId = isSender
                        ? req['receiverId']
                        : req['senderId'];
                    final peerName = isSender
                        ? req['receiverName']
                        : req['senderName'];
                    final peerEmail = isSender
                        ? req['receiverEmail']
                        : req['senderEmail'];
                    final peerPhoto = isSender
                        ? req['receiverPhotoURL']
                        : req['senderPhotoURL'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            peerPhoto != null && peerPhoto.isNotEmpty
                            ? NetworkImage(peerPhoto)
                            : null,
                        child: peerPhoto == null || peerPhoto.isEmpty
                            ? Text(
                                peerName != null && peerName.isNotEmpty
                                    ? peerName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(peerName ?? 'Unknown User'),
                      subtitle: Text(peerEmail ?? ''),
                      onTap: () {
                        Get.back(); // Dismiss forward selection sheet
                        controller.forwardMessage(message, peerId);
                      },
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller.messageFieldController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
            ),
          ),
          Obx(
            () => Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: controller.isSending.value
                    ? null
                    : controller.sendMessage,
                icon: controller.isSending.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
