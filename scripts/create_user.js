const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'uniride-a5bd7',
});

const db = admin.firestore();

async function createUser() {
  const now = admin.firestore.Timestamp.now();

  await db.collection('users').doc('3VwjCb4nk2hrJ3OCmYPNi7Bdnx52').set({
    name: 'Felipe Garcia',
    email: 'af.garciag1@uniandes.edu.co',
    reputationScore: 4.5,
    punctualityRate: 0.9,
    ridesPerMonth: 8,
    driverRating: 4.5,
    role: 'passenger',
    verified: true,
    createdAt: now,
    lastLogin: now,
    carModel: '',
    plate: '',
    seats: 0,
  });

  console.log('Document created successfully');
  process.exit(0);
}

createUser().catch((err) => {
  console.error(err);
  process.exit(1);
});
