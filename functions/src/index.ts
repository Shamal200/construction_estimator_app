import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

initializeApp();

const db = getFirestore();

type BusinessRole = 'owner' | 'admin' | 'estimator' | 'employee' | 'viewer';

const allowedRoles: BusinessRole[] = ['owner', 'admin', 'estimator', 'employee', 'viewer'];

function assertAuthenticated(auth: { uid: string } | undefined) {
  if (!auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }

  return auth.uid;
}

function normalizeBusinessPayload(data: Record<string, unknown>) {
  const companyName = String(data.companyName ?? '').trim();
  const address = String(data.address ?? '').trim();
  const phone = String(data.phone ?? '').trim();
  const email = String(data.email ?? '').trim();
  const currency = String(data.currency ?? '').trim();
  const defaultTaxRate = Number(data.defaultTaxRate ?? 0);

  if (!companyName || !address || !phone || !email || !currency) {
    throw new HttpsError('invalid-argument', 'Company name, address, phone, email, and currency are required.');
  }

  if (!Number.isFinite(defaultTaxRate) || defaultTaxRate < 0) {
    throw new HttpsError('invalid-argument', 'Default tax rate must be a valid percentage.');
  }

  return {
    companyName,
    address,
    phone,
    email,
    website: String(data.website ?? '').trim(),
    taxRegistrationNumber: String(data.taxRegistrationNumber ?? '').trim(),
    currency,
    defaultTaxRate,
  };
}

export const createBusiness = onCall(async (request) => {
  const uid = assertAuthenticated(request.auth);
  const payload = normalizeBusinessPayload((request.data ?? {}) as Record<string, unknown>);

  const businessId = `biz_${Date.now()}_${uid.slice(0, 8)}`;
  const businessRef = db.collection('businesses').doc(businessId);
  const memberRef = businessRef.collection('members').doc(uid);
  const userRef = db.collection('users').doc(uid);

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    const userData = userDoc.data() ?? {};
    const currentBusinessIds = Array.isArray(userData.businessIds) ? userData.businessIds as string[] : [];

    transaction.set(businessRef, {
      id: businessId,
      name: payload.companyName,
      address: payload.address,
      phone: payload.phone,
      email: payload.email,
      website: payload.website,
      taxRegistrationNumber: payload.taxRegistrationNumber,
      currency: payload.currency,
      defaultTaxRate: payload.defaultTaxRate,
      ownerId: uid,
      status: 'active',
      createdAt: FieldValue.serverTimestamp(),
    });

    transaction.set(memberRef, {
      userId: uid,
      businessId,
      role: 'owner',
      joinedAt: FieldValue.serverTimestamp(),
      isActive: true,
    });

    transaction.update(userRef, {
      businessIds: [...new Set([...currentBusinessIds, businessId])],
      activeBusinessId: businessId,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { businessId, status: 'created' };
});

export const createInvitation = onCall(async (request) => {
  const uid = assertAuthenticated(request.auth);
  const data = (request.data ?? {}) as Record<string, unknown>;

  const businessId = String(data.businessId ?? '').trim();
  const inviteEmail = String(data.email ?? '').trim();
  const role = String(data.role ?? 'employee').trim() as BusinessRole;
  const expiresAt = data.expiresAt ? new Date(String(data.expiresAt)) : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  if (!businessId || !inviteEmail || !allowedRoles.includes(role)) {
    throw new HttpsError('invalid-argument', 'A valid businessId, email, and role are required.');
  }

  const businessRef = db.collection('businesses').doc(businessId);
  const memberRef = businessRef.collection('members').doc(uid);
  const memberSnap = await memberRef.get();
  const memberData = memberSnap.data();

  if (!memberSnap.exists || !memberData || !['owner', 'admin'].includes(memberData.role)) {
    throw new HttpsError('permission-denied', 'Only owners or admins may create invitations.');
  }

  const invitationId = `inv_${Date.now()}_${uid.slice(0, 6)}`;
  await businessRef.collection('invitations').doc(invitationId).set({
    id: invitationId,
    businessId,
    email: inviteEmail,
    role,
    invitedByUserId: uid,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: expiresAt.toISOString(),
    status: 'pending',
  });

  return { invitationId, status: 'created' };
});

export const acceptInvitation = onCall(async (request) => {
  const uid = assertAuthenticated(request.auth);
  const data = (request.data ?? {}) as Record<string, unknown>;

  const invitationId = String(data.invitationId ?? '').trim();
  const businessId = String(data.businessId ?? '').trim();
  const email = String(data.email ?? '').trim();

  if (!invitationId || !businessId || !email) {
    throw new HttpsError('invalid-argument', 'Invitation ID, business ID, and email are required.');
  }

  const invitationRef = db.collection('businesses').doc(businessId).collection('invitations').doc(invitationId);
  const invitationSnap = await invitationRef.get();
  const invitation = invitationSnap.data();

  if (!invitationSnap.exists || !invitation) {
    throw new HttpsError('not-found', 'Invitation not found.');
  }

  if (invitation.email !== email) {
    throw new HttpsError('permission-denied', 'This invitation does not match the requested email address.');
  }

  if (invitation.status !== 'pending') {
    throw new HttpsError('failed-precondition', 'This invitation is no longer active.');
  }

  const expiry = invitation.expiresAt ? new Date(String(invitation.expiresAt)) : null;
  if (expiry && expiry.getTime() < Date.now()) {
    throw new HttpsError('failed-precondition', 'This invitation has expired.');
  }

  const memberRef = db.collection('businesses').doc(businessId).collection('members').doc(uid);
  const userRef = db.collection('users').doc(uid);

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    const userData = userDoc.data() ?? {};
    const currentBusinessIds = Array.isArray(userData.businessIds) ? userData.businessIds as string[] : [];

    transaction.set(memberRef, {
      userId: uid,
      businessId,
      role: invitation.role ?? 'employee',
      joinedAt: FieldValue.serverTimestamp(),
      isActive: true,
      invitationId,
    });

    transaction.update(userRef, {
      businessIds: [...new Set([...currentBusinessIds, businessId])],
      activeBusinessId: businessId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(invitationRef, {
      status: 'accepted',
      acceptedByUserId: uid,
      acceptedAt: FieldValue.serverTimestamp(),
    });
  });

  return { accepted: true, businessId, status: 'accepted' };
});

export const revokeInvitation = onCall(async (request) => {
  const uid = assertAuthenticated(request.auth);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const businessId = String(data.businessId ?? '').trim();
  const invitationId = String(data.invitationId ?? '').trim();

  if (!businessId || !invitationId) {
    throw new HttpsError('invalid-argument', 'Business ID and invitation ID are required.');
  }

  const businessRef = db.collection('businesses').doc(businessId);
  const memberRef = businessRef.collection('members').doc(uid);
  const memberSnap = await memberRef.get();
  const memberData = memberSnap.data();

  if (!memberSnap.exists || !memberData || !['owner', 'admin'].includes(memberData.role)) {
    throw new HttpsError('permission-denied', 'Only owners or admins may revoke invitations.');
  }

  await businessRef.collection('invitations').doc(invitationId).update({
    status: 'revoked',
    revokedByUserId: uid,
    revokedAt: FieldValue.serverTimestamp(),
  });

  return { revoked: true, invitationId };
});
