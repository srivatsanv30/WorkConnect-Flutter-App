const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
let messaging;
try {
  const serviceAccount = require('./serviceAccountKey.json');
  const app = initializeApp({
    credential: cert(serviceAccount),
  });
  messaging = getMessaging(app);
} catch (err) {
  console.warn('Firebase Admin SDK disabled: serviceAccountKey.json not found.');
  // Create a dummy messaging object so other files don't crash when calling methods
  messaging = {
    send: async () => console.log('Mock notification sent'),
    sendMulticast: async () => console.log('Mock multicast notification sent'),
  };
}

module.exports = { messaging };