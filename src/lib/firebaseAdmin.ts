import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  try {
    // If you add a service account JSON, you can initialize like:
    // const serviceAccount = require('../../service-account.json');
    // admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    
    // Otherwise, default to application default credentials (works in deployed environments)
    admin.initializeApp({
      projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    });
  } catch (error) {
    console.error('Firebase admin initialization error', error);
  }
}

export const adminDb = admin.firestore();
export const adminAuth = admin.auth();
