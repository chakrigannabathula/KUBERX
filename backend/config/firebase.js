const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const initializeFirebase = () => {
  try {
    if (!admin.apps.length) {
      // Use the service account JSON file directly
      const serviceAccountPath = path.join(__dirname, '..', 'kuberx-f1335-firebase-adminsdk-fbsvc-417e2a56c9.json');

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccountPath),
        projectId: 'kuberx-f1335',
      });

      console.log('✅ Firebase Admin initialized successfully');
    }
  } catch (error) {
    console.error('❌ Firebase initialization error:', error);
    // Don't throw error, just log it so server can still start
    console.warn('⚠️  Firebase Admin SDK not initialized. Some features may not work.');
  }
};

// Verify Firebase ID token
const verifyFirebaseToken = async (idToken) => {
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    console.error('Firebase token verification error:', error);
    throw new Error('Invalid Firebase token');
  }
};

// Get user info from Firebase
const getFirebaseUser = async (uid) => {
  try {
    const userRecord = await admin.auth().getUser(uid);
    return userRecord;
  } catch (error) {
    console.error('Firebase get user error:', error);
    throw new Error('Failed to get user from Firebase');
  }
};

module.exports = {
  initializeFirebase,
  verifyFirebaseToken,
  getFirebaseUser,
  admin
};
