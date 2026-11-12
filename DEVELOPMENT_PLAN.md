# BuildCalc Pro Development Plan: Spark Only

## Billing constraint

The Firebase project must remain on the Spark (free) plan. Do not upgrade to Blaze, enable billing, deploy Cloud Functions, or create other paid Firebase resources during this phase. Check the Firebase console for current Spark quotas before cloud testing; design and testing must stay within those limits.

## Allowed cloud services

- Firebase Authentication with email and password, password reset, and email verification, subject to current Spark quotas and configured Firebase settings.
- Cloud Firestore for user profiles and business-scoped application data, subject to current Spark quotas.
- No Cloud Storage, Cloud Functions, scheduled jobs, or other Firebase services are part of the active cloud app in this phase.

## Feature development

Continue building login, registration, profile management, workspace selection, customers, projects, quotations, invoices, materials, and related screens. Store company data only below `businesses/{businessId}`. Every Firestore request must be authorized from the membership document in security rules; `activeBusinessId` and `users/{userId}.businessIds` are preferences/index data, not authorization proofs.

Firestore CRUD for operational records can be developed directly against Firestore because access and role permissions are enforced by rules. Keep writes aligned with the serializers and validation in `firestore.rules`.

## Operations pending trusted backend

The following cannot be securely enabled as ordinary client Firestore writes and remain unavailable on the Spark cloud project until a trusted backend is approved and deployed in a later phase:

- Create a business and atomically establish its owner membership.
- Create, accept, and revoke email invitations.
- Add/remove members or assign/change business roles.
- Verify or change subscription entitlements.

Do not work around these restrictions by letting clients write owner/admin roles, invitation acceptance, or subscription fields. `functions/` is reference backend source only; it is not included in the production Firebase deploy config and must not be deployed under this plan. Review and security-test it before any future backend launch.

## Free-compatible local development

Use the Firebase Local Emulator Suite for Auth and Firestore, with the Functions emulator only if locally testing trusted backend code. Emulators run on the developer machine and do not require Firebase billing. The Flutter app can be pointed at Auth and Firestore emulators using:

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

On an Android emulator, use its host bridge:

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Start local services with:

```powershell
firebase emulators:start --config firebase.emulators.json --only auth,firestore
```

Use emulator-only fixtures or the Emulator UI/Admin SDK for local business and membership seed data. Never copy those privileged fixture writes into the production client. The normal `firebase.json` deliberately contains no Functions deployment target.

## Subscriptions and payments

Keep subscription plans and entitlements separate from business roles. Client profiles start on the free plan, and Firestore rules prevent clients from changing entitlement fields. Individual Pro, Business Pro, payment processing, and automated entitlement updates are deferred to a later phase with trusted backend verification.

## Release checklist

- Confirm Firebase project still reports Spark and no billing account is linked.
- Review and test `firestore.rules` in the Emulator Suite before any rules deployment.
- Confirm production Firebase config contains no Functions or paid-service deploy target.
- Check current Firebase quotas before cloud testing.
- Do not claim business creation, invitation operations, or subscription verification are live until a trusted backend exists and is security-tested.
