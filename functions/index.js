const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    if (!message) return null;

    const receiverId = message.receiverId;
    const senderId = message.senderId;
    const content = message.content;

    try {
      // 1. Fetch Receiver (to get FCM Token) and Sender (to get display name)
      const [receiverDoc, senderDoc] = await Promise.all([
        admin.firestore().collection("users").doc(receiverId).get(),
        admin.firestore().collection("users").doc(senderId).get()
      ]);

      if (!receiverDoc.exists || !senderDoc.exists) {
        console.log("Receiver or Sender profile does not exist.");
        return null;
      }

      const receiverData = receiverDoc.data();
      const senderData = senderDoc.data();
      const fcmToken = receiverData.fcmToken;

      if (!fcmToken) {
        console.log("Receiver has no FCM Token registered.");
        return null;
      }

      // 2. Prepare the messaging payload (FCM v1 format)
      const payload = {
        token: fcmToken,
        notification: {
          title: senderData.displayName || "New Message",
          body: content,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          chatId: context.params.chatId,
          senderId: senderId,
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            channelId: "high_importance_channel"
          }
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1
            }
          }
        }
      };

      // 3. Send the notification
      const response = await admin.messaging().send(payload);
      console.log("Notification sent successfully:", response);
      return null;
    } catch (e) {
      console.error("Error sending push notification:", e);
      return null;
    }
  });
