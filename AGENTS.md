# AGENTS.md

Flutter restaurant QR-ordering + POS app. Customer side browses a menu and places orders; POS side tracks and updates order status. State via `provider` (ChangeNotifier), backend is Firestore.

## Commands

- Analyze/lint: `flutter analyze`
- Tests: `flutter test`
- Run POS app: `flutter run -t lib/main_pos.dart`; build POS: `flutter build apk --target=lib/main_pos.dart` (or `--windows`, `--linux`, etc.)
- Build customer web app: `flutter build web` (default target `lib/main.dart`)
- Regenerate Firebase config: `flutterfire configure` (uses `firebase.json`; project `restorent-pos-system`, writes `lib/firebase_options.dart` + platform `google-services.json`/`GoogleService-Info.plist`)

## Architecture

- Two entrypoints, one per role:
  - `lib/main.dart` — customer web app. `CustomerHomeScreen` reads `Uri.base.queryParameters['table']`; when the QR deep link (`/menu?table=<n>`) is loaded it opens `MenuScreen(tableNumber: ...)` directly. No POS/QR-manager access.
  - `lib/main_pos.dart` — POS app for reception/admin. Home is `DashboardScreen` (order status tabs + QR code manager tab).
- Both boot with `Firebase.initializeApp`; customer app is wrapped in `MultiProvider` with `CartProvider` (only provider).
- Firestore collections (field names are the contract — models in `lib/models/`):
  - `menu`: `name`, `description`, `price` (double), `imageUrl`, `category`
  - `orders`: `tableNumber`, `items` (list of `{menuItem, quantity}` maps), `totalAmount`, `status` (`pending` → `preparing` → `completed`), `createdAt` (Timestamp), `paymentId`
- Status updates happen directly in `lib/screens/pos/dashboard_screen.dart` via `FirebaseFirestore` doc updates.

## Deploy (Firebase Hosting)

- CI: `.github/workflows/firebase-deploy.yml` builds both apps and deploys on push to `main`. Auth via `firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_RESTORENT_POS_SYSTEM }}` (service-account JSON secret, created by the Firebase console wizard; `FIREBASE_TOKEN` is deprecated).
- One Hosting site, two apps: customer at `/` (`build/web`), POS at `/pos/` (built with `--output build/web_pos --target lib/main_pos.dart --base-href=/pos/`), staged into `public/` (gitignored). `firebase.json` rewrites `/pos*` to `/pos/index.html` and everything else to `/index.html` (SPA).
- `flutterfire configure` preserves the `hosting` key in `firebase.json`; if it ever rewrites the file, re-add hosting.

## Gotchas

- `MenuScreen` uses hardcoded demo menu items whenever the Firestore `menu` collection is empty; a missing collection is not a bug.
- POS dashboards query `where('status', ...) + orderBy('createdAt')` — Firestore needs a composite index on `orders` (create once via the console link shown in the error).
- Firestore rules currently allow all (password-free); tighten before public use.
- `lib/screens/pos/table_qr_screen.dart` `_baseUrl` must match the deployed site (currently `https://restorent-pos-system.web.app/menu?table=`); change together with the domain.
- Currency is ₹ throughout; prices rendered with `toStringAsFixed(2)`.
- Password-free Firebase: emulator setup, auth, and payment (Razorpay placeholder in `CartProvider.placeOrder`) are not implemented.