import * as admin from 'firebase-admin';

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrate() {
  const snapshot = await db.collection('orders').get();
  let count = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.isRead === undefined) {
      await doc.ref.update({ isRead: false });
      count++;
    }
  }
  console.log(`Migrated ${count} orders.`);
}

migrate().catch(console.error);
