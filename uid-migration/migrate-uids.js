/**
 * update-passwords.js
 *
 * Sets a new password for each user in your project, by uid.
 * Uses the same modular firebase-admin API as migrate-uids.js
 * (the one that worked, avoiding the admin.credential.cert bug).
 *
 * SETUP
 * Reuses the same folder as migrate-uids.js — same serviceAccountKey.json,
 * same node_modules. No new installs needed.
 *
 * 1. Edit the `newPassword` value for each user below.
 * 2. Run: node update-passwords.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount),
});

const auth = getAuth();

// Same 4 users from the migration. Set whatever password you want for each.
const usersToUpdate = [
  {
    uid: 'VBLVYdMPrqXNdbAzvNIqprDbqFo2',
    email: 'karangoplani72@gmail.com',
    newPassword: 'Karan@123',
  },
  {
    uid: 'fYbmtBMSY0O12pypZRdT3tNXGaG2',
    email: 'karangoplani81@gmail.com',
    newPassword: 'Karan@123',
  },
  {
    uid: 'gVs6DZek3TOEPh9v0ysWMSeEbIf1',
    email: 'karangoplani73@gmail.com',
    newPassword: 'Karan@123',
  },
  {
    uid: 'iJOM1XLgm3eupX8XOR2mP92kDnb2',
    email: 'karan.dishahire@gmail.com',
    newPassword: 'Karan@123',
  },
];

async function updatePasswords() {
  for (const user of usersToUpdate) {
    try {
      await auth.updateUser(user.uid, { password: user.newPassword });
      console.log(`Updated password for ${user.email} (${user.uid})`);
    } catch (err) {
      console.error(`Failed for ${user.email}:`, err.message);
    }
  }
  console.log('Done.');
}

updatePasswords();