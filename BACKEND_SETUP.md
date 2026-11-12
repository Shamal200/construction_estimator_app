# BuildCalc Pro backend status under Firebase Spark

The project must remain on Firebase Spark. No Cloud Functions or other paid resources are to be deployed, and billing must not be enabled.

## Active cloud scope

The app uses Firebase Authentication (email/password) and Cloud Firestore, subject to the current Spark quotas shown in the Firebase console. The active production Firebase config has no Cloud Functions deployment target. Cloud Storage has been removed from the Flutter dependencies because it is not currently used by the app and is outside this phase's allowed service scope.

## Pending trusted operations

The source under `functions/` is reference architecture only and is not deployed. The following actions intentionally fail closed in the Flutter client:

- Business creation and owner membership bootstrap
- Invitation creation, acceptance, and revocation
- Membership and role assignment/management
- Subscription entitlement verification or updates

Do not replace these with direct client writes. Firestore rules deny client writes to businesses, member records, invitations, and subscription fields. These operations need a trusted backend and security review before a later deployment phase. No backend operation is represented as live.

## Local development

Use `firebase.emulators.json` to run local Auth and Firestore. The Flutter app can connect by passing `--dart-define=USE_FIREBASE_EMULATORS=true`; for an Android emulator, also pass `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2`.

Optional local Functions emulator use is for backend development and testing only; it is not a deployment instruction and does not create a paid cloud resource. Keep any privileged test seeding confined to emulators.

## Review before any later backend phase

Before a future backend launch, security-test the callable function source, verify invitation email against the authenticated Firebase token (not a caller-supplied email), constrain assignable roles, validate expiry, and test membership/profile writes atomically. Do not deploy the current reference source without that review.
