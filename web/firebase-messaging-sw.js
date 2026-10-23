importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCoPrDy4c4GKbXPcWDX6opRePo1JtZdhY8",
  authDomain: "workconnect-65a88.firebaseapp.com",
  projectId: "workconnect-65a88",
  storageBucket: "workconnect-65a88.firebasestorage.app",
  messagingSenderId: "613148055539",
  appId: "1:613148055539:web:bff71d6ae0922e0795a486",
  measurementId: "G-C9W9ZY2XTF"
});

const messaging = firebase.messaging();

// Optional background message handler
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message: ', payload);
  const notificationTitle = payload.notification?.title || 'WorkConnect';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/favicon.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
