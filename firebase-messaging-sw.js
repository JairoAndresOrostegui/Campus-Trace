// web/firebase-messaging-sw.js

// Usa la versión que prefieras de Firebase JS, aquí un ejemplo 10.x
importScripts('https://www.gstatic.com/firebasejs/10.12.3/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.3/firebase-messaging-compat.js');

// ⚠️ PON AQUÍ TU CONFIGURACIÓN WEB (la misma de DefaultFirebaseOptions para web)
firebase.initializeApp({
  apiKey: 'AIzaSyAOFLpweNS3QFj79RYjC-HqxrDMOfNg1DM',
  authDomain: 'campustrace-645c3.firebaseapp.com',
  projectId: 'campustrace-645c3',
  storageBucket: 'campustrace-645c3.firebasestorage.app',
  messagingSenderId: '214929294248',
  appId: '1:214929294248:web:ee32da31b9fb792152939d',
  measurementId: 'G-2FGCX1LVPQ',
});

// Inicializa messaging en el SW
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'Notificación';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
