// Import the Firebase SDKs (Compat versions)
importScripts("https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js");

// Initialize Firebase
firebase.initializeApp({
  apiKey: "AIzaSyAwVKS8xXeutUjXDsSIVbuLhTTn7AcNKHI",
  authDomain: "chat-app-b594b.firebaseapp.com",
  projectId: "chat-app-b594b",
  storageBucket: "chat-app-b594b.firebasestorage.app",
  messagingSenderId: "664222473723",
  appId: "1:664222473723:web:8b0b220c9b7fd5d080bf5e"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log("Received background message in service worker: ", payload);
  const notificationTitle = payload.notification?.title || "New Message";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
    data: payload.data
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});
