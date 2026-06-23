importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD-valJIvynF2ZJJcNdojih8xUTMruvWPY",
  authDomain: "ecom-750fc.firebaseapp.com",
  projectId: "ecom-750fc",
  storageBucket: "ecom-750fc.firebasestorage.app",
  messagingSenderId: "282984146836",
  appId: "1:282984146836:web:582a099fc0809296f8d181"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || "ecom Notification";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
