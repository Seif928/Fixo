/* Firebase client configuration is public. No server credentials belong here.
 * Keep this SDK version aligned with firebase_core_web's supported JS SDK.
 */
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyC-lFRkdTIoWx0ZJtA-Z3aEm6rESE86A-s',
  appId: '1:98803341231:web:b1079d4cb366879874c15a',
  messagingSenderId: '98803341231',
  projectId: 'fixo-home-services-6507',
  authDomain: 'fixo-home-services-6507.firebaseapp.com',
  storageBucket: 'fixo-home-services-6507.firebasestorage.app',
});

// Notification payloads are displayed by the SDK in the background; do not
// display a duplicate notification or expose chat contents in this worker.
firebase.messaging();
