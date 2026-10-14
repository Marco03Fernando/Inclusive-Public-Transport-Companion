// Firestore security-rules checks for ColomboPal (Community Reports
// publication, reporter consent, privacy of private reports).
//
// Run from this folder:  npm install && npm test
// Uses the local emulator with a demo- project ID, so it can never read or
// write the real Firebase project.
//
// Every write mirrors the app's exact document shapes (see
// firebase_condition_report_repository.dart, firebase_admin_report_repository.dart,
// firebase_community_report_repository.dart).
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, runTransaction,
  collection, query, orderBy, limit, getDocs, Timestamp, serverTimestamp,
} from 'firebase/firestore';

const rulesPath = process.argv[2];
const env = await initializeTestEnvironment({
  projectId: 'demo-colombopal',
  firestore: { rules: readFileSync(rulesPath, 'utf8') },
});

let passed = 0, failed = 0;
async function check(name, fn) {
  try { await fn(); passed++; console.log(`  ok   ${name}`); }
  catch (e) { failed++; console.log(`  FAIL ${name}\n       ${e.message.split('\n')[0]}`); }
}

const created = Timestamp.fromDate(new Date('2026-10-01T09:20:00Z'));

// FirebaseConditionReportRepository._toDocument
function reportDoc(id, uid, extra = {}) {
  return {
    reportId: id, userId: uid, reportType: 'issue', routeNumber: '138A', routeId: '138A',
    subject: 'bus', vehicleOrStationNumber: 'NB-1234', conditionType: 'brokenRamp',
    description: 'Ramp is bent and will not lower.', locationName: 'Current location attached',
    latitude: 6.927149, longitude: 79.861244, photoUrl: null, status: 'underReview',
    adminComment: null, shareWithCommunity: false, publicDisplayName: null,
    createdAt: created, updatedAt: created, ...extra,
  };
}

// buildPublicReportProjection
const approx = (v) => (typeof v === 'number' ? Math.round(v * 1000) / 1000 : null);
function projection(src, status) {
  return {
    reportType: src.reportType, routeNumber: src.routeNumber ?? '', routeId: src.routeId ?? '',
    subject: src.subject, vehicleOrStationNumber: src.vehicleOrStationNumber ?? '',
    conditionType: src.conditionType, description: src.description ?? '',
    locationName: src.locationName ?? '', latitude: approx(src.latitude),
    longitude: approx(src.longitude), photoUrl: src.photoUrl ?? null,
    contributorName: src.publicDisplayName ?? null, status, createdAt: src.createdAt,
    publishedAt: serverTimestamp(),
  };
}

// FirebaseAdminReportRepository.reviewReport
async function review(db, id, decision, { publish = true, tamper } = {}) {
  await runTransaction(db, async (tx) => {
    const ref = doc(db, 'condition_reports', id);
    const snap = await tx.get(ref);
    tx.update(ref, { status: decision, adminComment: 'ok', updatedAt: serverTimestamp() });
    const src = { ...snap.data(), status: decision };
    const pubRef = doc(db, 'public_condition_reports', id);
    const eligible = ['accepted', 'verified'].includes(decision)
      && src.shareWithCommunity === true && ['positive', 'issue'].includes(src.reportType);
    if (publish && (eligible || tamper)) tx.set(pubRef, { ...projection(src, decision), ...(tamper ?? {}) });
    else if (src.shareWithCommunity === true) tx.delete(pubRef);
  });
}

async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

await seed(async (db) => {
  await setDoc(doc(db, 'users/admin'), { role: 'admin', name: 'Admin' });
  await setDoc(doc(db, 'users/alice'), { role: 'passenger', name: 'Alice Perera', email: 'a@x.lk', phone: '077' });
  await setDoc(doc(db, 'users/bob'), { role: 'volunteer', name: 'Bob' });
});

const alice = env.authenticatedContext('alice').firestore();
const bob = env.authenticatedContext('bob').firestore();
const admin = env.authenticatedContext('admin').firestore();
const anon = env.unauthenticatedContext().firestore();

console.log('\nReport submission + consent');
await check('reporter creates a private report (no consent)', () =>
  assertSucceeds(setDoc(doc(alice, 'condition_reports/r-private'), reportDoc('r-private', 'alice'))));
await check('reporter creates a shared anonymous report', () =>
  assertSucceeds(setDoc(doc(alice, 'condition_reports/r-anon'),
    reportDoc('r-anon', 'alice', { shareWithCommunity: true, reportType: 'positive' }))));
await check('reporter creates a shared report with own profile name', () =>
  assertSucceeds(setDoc(doc(alice, 'condition_reports/r-named'),
    reportDoc('r-named', 'alice', { shareWithCommunity: true, publicDisplayName: 'Alice Perera' }))));
await check('legacy-shaped report (no consent fields) still accepted', async () => {
  const d = reportDoc('r-legacy', 'alice'); delete d.shareWithCommunity; delete d.publicDisplayName;
  await assertSucceeds(setDoc(doc(alice, 'condition_reports/r-legacy'), d));
});
await check('DENY public name that is not the reporter profile name', () =>
  assertFails(setDoc(doc(alice, 'condition_reports/r-spoof'),
    reportDoc('r-spoof', 'alice', { shareWithCommunity: true, publicDisplayName: 'Bob' }))));
await check('DENY public name without sharing consent', () =>
  assertFails(setDoc(doc(alice, 'condition_reports/r-noshare'),
    reportDoc('r-noshare', 'alice', { publicDisplayName: 'Alice Perera' }))));
await check('DENY non-boolean consent', () =>
  assertFails(setDoc(doc(alice, 'condition_reports/r-badbool'),
    reportDoc('r-badbool', 'alice', { shareWithCommunity: 'yes' }))));
await check('DENY report created as already accepted', () =>
  assertFails(setDoc(doc(alice, 'condition_reports/r-pre'),
    reportDoc('r-pre', 'alice', { shareWithCommunity: true, status: 'accepted' }))));
await check('DENY reporter changing consent after submission', () =>
  assertFails(updateDoc(doc(alice, 'condition_reports/r-private'), { shareWithCommunity: true })));
await check('DENY reporter self-approving', () =>
  assertFails(updateDoc(doc(alice, 'condition_reports/r-anon'), { status: 'accepted' })));

console.log('\nPublication (admin only, verified + consented only)');
await check('DENY reporter writing their own public copy', async () => {
  const src = reportDoc('r-anon', 'alice', { shareWithCommunity: true, reportType: 'positive' });
  await assertFails(setDoc(doc(alice, 'public_condition_reports/r-anon'), projection(src, 'accepted')));
});
await check('DENY admin publishing an unverified report', async () => {
  const src = reportDoc('r-anon', 'alice', { shareWithCommunity: true, reportType: 'positive' });
  await assertFails(setDoc(doc(admin, 'public_condition_reports/r-anon'), projection(src, 'underReview')));
});
await check('admin accept publishes anonymous report in same transaction', () =>
  assertSucceeds(review(admin, 'r-anon', 'accepted')));
await check('admin accept publishes named report in same transaction', () =>
  assertSucceeds(review(admin, 'r-named', 'accepted')));
await check('accepting a NON-consented report creates no public copy', async () => {
  await assertSucceeds(review(admin, 'r-private', 'accepted'));
  let exists = true;
  await env.withSecurityRulesDisabled(async (ctx) => {
    exists = (await getDoc(doc(ctx.firestore(), 'public_condition_reports/r-private'))).exists();
  });
  if (exists) throw new Error('public copy exists');
});
await check('DENY publishing a non-consented accepted report', async () => {
  const src = reportDoc('r-private', 'alice', { status: 'accepted' });
  await assertFails(setDoc(doc(admin, 'public_condition_reports/r-private'), projection(src, 'accepted')));
});
await check('DENY publishing legacy report (no consent field)', async () => {
  await assertSucceeds(review(admin, 'r-legacy', 'accepted', { publish: false }));
  const src = reportDoc('r-legacy', 'alice', { status: 'accepted' });
  delete src.shareWithCommunity; delete src.publicDisplayName;
  await assertFails(setDoc(doc(admin, 'public_condition_reports/r-legacy'), projection(src, 'accepted')));
});

// Tampering / data-leak attempts on an eligible report.
await seed(async (db) => setDoc(doc(db, 'condition_reports/r-t'),
  reportDoc('r-t', 'alice', { shareWithCommunity: true, status: 'accepted', publicDisplayName: 'Alice Perera' })));
const tSrc = reportDoc('r-t', 'alice', { shareWithCommunity: true, status: 'accepted', publicDisplayName: 'Alice Perera' });
for (const [label, patch] of [
  ['userId (private field)', { userId: 'alice' }],
  ['exact coordinates', { latitude: 6.927149 }],
  ['coordinates off by one rounding step', { latitude: 6.928 }],
  ['coordinates with extra precision', { longitude: 79.8612 }],
  ['altered description', { description: 'edited' }],
  ['altered contributor name', { contributorName: 'Someone else' }],
  ['adminComment', { adminComment: 'internal' }],
  ['client-chosen publishedAt', { publishedAt: created }],
  ['claimed status', { status: 'verified' }],
]) {
  await check(`DENY projection with ${label}`, () =>
    assertFails(setDoc(doc(admin, 'public_condition_reports/r-t'), { ...projection(tSrc, 'accepted'), ...patch })));
}
await check('admin re-publish (setPublished) of eligible report', () =>
  assertSucceeds(setDoc(doc(admin, 'public_condition_reports/r-t'), projection(tSrc, 'accepted'))));

console.log('\nReading');
const vSrc = reportDoc('r-v', 'alice', { shareWithCommunity: true, status: 'verified', latitude: null, longitude: null });
await seed(async (db) => setDoc(doc(db, 'condition_reports/r-v'), vSrc));
await check('admin publishes legacy-"verified" consented report without coordinates', () =>
  assertSucceeds(setDoc(doc(admin, 'public_condition_reports/r-v'), projection(vSrc, 'verified'))));
await check('DENY coordinates on a report that had none', () =>
  assertFails(setDoc(doc(admin, 'public_condition_reports/r-v'), { ...projection(vSrc, 'verified'), latitude: 6.927 })));
await seed(async (db) => deleteDoc(doc(db, 'public_condition_reports/r-v')));
// Rounding parity with Dart's (v * 1000).round() / 1000 for awkward values.
for (const [lat, lng] of [[6.9275, 79.8615], [7.2905999, 80.6337001], [6.0001, 81.0009]]) {
  const id = `r-round-${lat}`;
  const src = reportDoc(id, 'alice', { shareWithCommunity: true, status: 'accepted', latitude: lat, longitude: lng });
  await seed(async (db) => setDoc(doc(db, `condition_reports/${id}`), src));
  await check(`rounded coordinates accepted for ${lat}, ${lng}`, () =>
    assertSucceeds(setDoc(doc(admin, `public_condition_reports/${id}`), projection(src, 'accepted'))));
  await seed(async (db) => deleteDoc(doc(db, `public_condition_reports/${id}`)));
}

await check('other user reads a public copy', () =>
  assertSucceeds(getDoc(doc(bob, 'public_condition_reports/r-anon'))));
await check('other user runs the feed query', async () => {
  const snap = await assertSucceeds(getDocs(query(collection(bob, 'public_condition_reports'),
    orderBy('createdAt', 'desc'), limit(51))));
  if (snap.size !== 3) throw new Error(`expected 3 published, got ${snap.size}`);
  for (const d of snap.docs) {
    const keys = Object.keys(d.data());
    for (const bad of ['userId', 'adminComment', 'email', 'phone', 'shareWithCommunity', 'publicDisplayName', 'updatedAt']) {
      if (keys.includes(bad)) throw new Error(`public copy leaks ${bad}`);
    }
  }
});
await check('DENY signed-out read of the feed', () =>
  assertFails(getDocs(query(collection(anon, 'public_condition_reports'), limit(5)))));
await check("DENY other user reading someone's private report", () =>
  assertFails(getDoc(doc(bob, 'condition_reports/r-anon'))));
await check('DENY other user listing all private reports', () =>
  assertFails(getDocs(collection(bob, 'condition_reports'))));
await check('owner still reads own reports (My Reports query)', async () => {
  const { where } = await import('firebase/firestore');
  await assertSucceeds(getDocs(query(collection(alice, 'condition_reports'),
    where('userId', '==', 'alice'), orderBy('createdAt', 'desc'))));
});
await check("DENY reading another user's profile", () =>
  assertFails(getDoc(doc(bob, 'users/alice'))));

console.log('\nRemoval');
await check('DENY other user deleting a public copy', () =>
  assertFails(deleteDoc(doc(bob, 'public_condition_reports/r-anon'))));
await check('admin reject removes public copy in same transaction', async () => {
  await assertSucceeds(review(admin, 'r-named', 'rejected'));
  const snap = await getDoc(doc(bob, 'public_condition_reports/r-named'));
  if (snap.exists()) throw new Error('still public after rejection');
});
await check('admin unpublish (delete public copy)', () =>
  assertSucceeds(deleteDoc(doc(admin, 'public_condition_reports/r-t'))));
await check('owner retracts own report + public copy in one batch', async () => {
  const b = writeBatch(alice);
  b.delete(doc(alice, 'condition_reports/r-anon'));
  b.delete(doc(alice, 'public_condition_reports/r-anon'));
  await assertSucceeds(b.commit());
});
await seed(async (db) => {
  const src = reportDoc('r-del', 'alice', { shareWithCommunity: true, status: 'accepted' });
  await setDoc(doc(db, 'condition_reports/r-del'), src);
  await setDoc(doc(db, 'public_condition_reports/r-del'), { ...projection(src, 'accepted'), publishedAt: created });
});
await check('admin deletes report + public copy in one batch', async () => {
  const b = writeBatch(admin);
  b.delete(doc(admin, 'condition_reports/r-del'));
  b.delete(doc(admin, 'public_condition_reports/r-del'));
  await assertSucceeds(b.commit());
});

console.log('\nExisting rules unaffected');
await check('user creates own passenger profile', () =>
  assertSucceeds(setDoc(doc(env.authenticatedContext('carol').firestore(), 'users/carol'),
    { role: 'passenger', name: 'Carol', email: '', phone: '', dob: '', accessNeeds: [], isAnonymous: false })));
await check('DENY self-created admin profile', () =>
  assertFails(setDoc(doc(env.authenticatedContext('dave').firestore(), 'users/dave'),
    { role: 'admin', name: 'Dave' })));
await check('DENY changing own role', () =>
  assertFails(updateDoc(doc(alice, 'users/alice'), { role: 'admin' })));

await env.cleanup();
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
