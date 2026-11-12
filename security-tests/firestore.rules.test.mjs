import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'demo-buildcalc-rules';
const rules = await readFile(new URL('../firestore.rules', import.meta.url), 'utf8');
let testEnvironment;

const roles = {
  owner: { uid: 'user-owner', role: 'owner' },
  admin: { uid: 'user-admin', role: 'admin' },
  estimator: { uid: 'user-estimator', role: 'estimator' },
  employee: { uid: 'user-employee', role: 'employee' },
  viewer: { uid: 'user-viewer', role: 'viewer' },
};

function authenticatedDb(uid) {
  return testEnvironment.authenticatedContext(uid, {
    email: `${uid}@example.test`,
  }).firestore();
}

function userProfile(uid, businessIds = []) {
  return {
    uid,
    fullName: uid,
    email: `${uid}@example.test`,
    createdAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
    activeBusinessId: null,
    businessIds,
    subscriptionPlan: 'free',
    subscriptionStatus: 'active',
  };
}

function membership(businessId, uid, role) {
  return {
    userId: uid,
    businessId,
    role,
    joinedAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
    isActive: true,
  };
}

function customer(id) {
  return {
    id,
    fullName: 'Test Customer',
    companyName: 'Test Co',
    phoneNumber: '',
    email: 'customer@example.test',
    address: '1 Test Street',
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
  };
}

function quotation(id) {
  return {
    id,
    quotationNumber: 'Q-001',
    customerId: 'customer-1',
    customerName: 'Test Customer',
    projectName: 'Test Project',
    projectAddress: '1 Test Street',
    description: '',
    issueDate: '2026-01-01T00:00:00.000Z',
    validUntil: '2026-02-01T00:00:00.000Z',
    notes: '',
    termsAndConditions: '',
    items: [],
    markupPercent: 0,
    discount: 0,
    taxPercent: 0,
    status: 'Draft',
  };
}

function invoice(id) {
  return {
    id,
    invoiceNumber: 'I-001',
    customerId: 'customer-1',
    projectId: 'project-1',
    issueDate: '2026-01-01T00:00:00.000Z',
    dueDate: '2026-02-01T00:00:00.000Z',
    items: [],
    subtotal: 100,
    tax: 10,
    total: 110,
    amountPaid: 0,
    balance: 110,
    status: 'draft',
  };
}

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

after(async () => {
  await testEnvironment?.cleanup();
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'businesses/business-a'), {
      id: 'business-a',
      name: 'Business A',
      status: 'active',
      subscriptionPlan: 'free',
    });
    await setDoc(doc(db, 'businesses/business-b'), {
      id: 'business-b',
      name: 'Business B',
      status: 'active',
      subscriptionPlan: 'free',
    });

    for (const { uid, role } of Object.values(roles)) {
      await setDoc(doc(db, `businesses/business-a/members/${uid}`),
        membership('business-a', uid, role));
      await setDoc(doc(db, `users/${uid}`), userProfile(uid, ['business-a']));
    }

    await setDoc(doc(db, 'businesses/business-b/members/user-other-business'),
      membership('business-b', 'user-other-business', 'employee'));
    await setDoc(doc(db, 'users/user-other-business'),
      userProfile('user-other-business', ['business-b']));
    await setDoc(doc(db, 'users/user-outsider'), userProfile('user-outsider'));

    await setDoc(doc(db, 'businesses/business-a/customers/customer-1'), customer('customer-1'));
    await setDoc(doc(db, 'businesses/business-b/customers/customer-2'), customer('customer-2'));
    await setDoc(doc(db, 'businesses/business-a/quotations/quotation-1'), quotation('quotation-1'));
    await setDoc(doc(db, 'businesses/business-a/invoices/invoice-1'), invoice('invoice-1'));
  });
});

test('unauthenticated users cannot access protected records', async () => {
  const db = testEnvironment.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/user-owner')));
  await assertFails(getDoc(doc(db, 'businesses/business-a/customers/customer-1')));
});

test('authenticated users can access their own permitted profile only', async () => {
  const db = authenticatedDb(roles.employee.uid);
  await assertSucceeds(getDoc(doc(db, `users/${roles.employee.uid}`)));
  await assertFails(getDoc(doc(db, `users/${roles.owner.uid}`)));
  await assertSucceeds(updateDoc(doc(db, `users/${roles.employee.uid}`), {
    fullName: 'Updated Employee',
  }));
});

test('business members are isolated to businesses where they have membership', async () => {
  const memberDb = authenticatedDb(roles.employee.uid);
  await assertSucceeds(getDoc(doc(memberDb, 'businesses/business-a')));
  await assertSucceeds(getDoc(doc(memberDb, 'businesses/business-a/customers/customer-1')));
  await assertFails(getDoc(doc(memberDb, 'businesses/business-b')));
  await assertFails(getDoc(doc(memberDb, 'businesses/business-b/customers/customer-2')));

  const outsiderDb = authenticatedDb('user-outsider');
  await assertFails(getDoc(doc(outsiderDb, 'businesses/business-a')));
});

test('users cannot create owner membership or change their own role', async () => {
  const outsiderDb = authenticatedDb('user-outsider');
  await assertFails(setDoc(
    doc(outsiderDb, 'businesses/business-a/members/user-outsider'),
    membership('business-a', 'user-outsider', 'owner'),
  ));

  const estimatorDb = authenticatedDb(roles.estimator.uid);
  await assertFails(updateDoc(
    doc(estimatorDb, `businesses/business-a/members/${roles.estimator.uid}`),
    { role: 'owner' },
  ));
});

test('ordinary users cannot create invitations or modify membership records', async () => {
  const employeeDb = authenticatedDb(roles.employee.uid);
  await assertFails(setDoc(
    doc(employeeDb, 'businesses/business-a/invitations/invite-1'),
    {
      id: 'invite-1',
      businessId: 'business-a',
      email: 'new@example.test',
      role: 'employee',
      status: 'pending',
      expiresAt: '2026-12-01T00:00:00.000Z',
    },
  ));
  await assertFails(updateDoc(
    doc(employeeDb, `businesses/business-a/members/${roles.viewer.uid}`),
    { isActive: false },
  ));
});

test('users cannot upgrade profile or business subscriptions', async () => {
  const db = authenticatedDb(roles.owner.uid);
  await assertFails(updateDoc(doc(db, `users/${roles.owner.uid}`), {
    subscriptionPlan: 'individualPro',
    subscriptionStatus: 'active',
  }));
  await assertFails(updateDoc(doc(db, 'businesses/business-a'), {
    subscriptionPlan: 'businessPro',
  }));
  await assertFails(updateDoc(doc(db, `users/${roles.owner.uid}`), {
    businessIds: ['business-a', 'business-b'],
    activeBusinessId: 'business-b',
  }));
  await assertFails(updateDoc(doc(db, `users/${roles.owner.uid}`), {
    activeBusinessId: 'business-b',
  }));
});

test('authorized business members can read and create permitted customer records', async () => {
  const estimatorDb = authenticatedDb(roles.estimator.uid);
  await assertSucceeds(getDoc(doc(estimatorDb, 'businesses/business-a/customers/customer-1')));
  await assertSucceeds(setDoc(
    doc(estimatorDb, 'businesses/business-a/customers/customer-new'),
    customer('customer-new'),
  ));
});

test('viewers cannot create or modify customer or quotation records', async () => {
  const viewerDb = authenticatedDb(roles.viewer.uid);
  await assertFails(setDoc(
    doc(viewerDb, 'businesses/business-a/customers/customer-viewer'),
    customer('customer-viewer'),
  ));
  await assertFails(updateDoc(
    doc(viewerDb, 'businesses/business-a/quotations/quotation-1'),
    { status: 'Accepted' },
  ));
});

test('estimators can create quotations but cannot write invoices or delete records', async () => {
  const estimatorDb = authenticatedDb(roles.estimator.uid);
  await assertSucceeds(setDoc(
    doc(estimatorDb, 'businesses/business-a/quotations/quotation-new'),
    quotation('quotation-new'),
  ));
  await assertFails(setDoc(
    doc(estimatorDb, 'businesses/business-a/invoices/invoice-new'),
    invoice('invoice-new'),
  ));
  await assertSucceeds(setDoc(
    doc(estimatorDb, 'businesses/business-a/materials/material-new'),
    {
      id: 'material-new',
      name: 'Concrete mix',
      category: 'Concrete',
      unit: 'bag',
      cost: 12.5,
      isActive: true,
    },
  ));
  await assertFails(deleteDoc(
    doc(estimatorDb, 'businesses/business-a/customers/customer-1'),
  ));
});

test('employees can write customer and project records but not invoice operations', async () => {
  const employeeDb = authenticatedDb(roles.employee.uid);
  await assertSucceeds(setDoc(
    doc(employeeDb, 'businesses/business-a/customers/customer-employee'),
    customer('customer-employee'),
  ));
  await assertSucceeds(setDoc(
    doc(employeeDb, 'businesses/business-a/projects/project-employee'),
    {
      id: 'project-employee',
      name: 'Employee Project',
      customerId: 'customer-1',
      address: '1 Test Street',
      startDate: '2026-01-01T00:00:00.000Z',
      expectedCompletionDate: '2026-02-01T00:00:00.000Z',
      status: 'Planning',
    },
  ));
  await assertFails(setDoc(
    doc(employeeDb, 'businesses/business-a/quotations/quotation-employee'),
    quotation('quotation-employee'),
  ));
  await assertFails(setDoc(
    doc(employeeDb, 'businesses/business-a/materials/material-employee'),
    {
      id: 'material-employee',
      name: 'Concrete mix',
      category: 'Concrete',
      unit: 'bag',
      cost: 12.5,
      isActive: true,
    },
  ));
  await assertSucceeds(getDoc(doc(employeeDb, 'businesses/business-a/invoices/invoice-1')));
  await assertFails(updateDoc(
    doc(employeeDb, 'businesses/business-a/invoices/invoice-1'),
    { status: 'paid' },
  ));
  await assertFails(deleteDoc(
    doc(employeeDb, 'businesses/business-a/invoices/invoice-1'),
  ));
});

test('unauthorized users cannot delete business records', async () => {
  const outsiderDb = authenticatedDb('user-outsider');
  await assertFails(deleteDoc(
    doc(outsiderDb, 'businesses/business-a/customers/customer-1'),
  ));

  const viewerDb = authenticatedDb(roles.viewer.uid);
  await assertFails(deleteDoc(
    doc(viewerDb, 'businesses/business-a/quotations/quotation-1'),
  ));
});
