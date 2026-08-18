# AGENTS.md

Flutter restaurant QR-ordering + POS app. Customer side browses a menu and places orders; POS side tracks and updates order status. State via `provider` (ChangeNotifier), backend is Firestore.

## Commands

- Analyze/lint: `flutter analyze`
- Tests: `flutter test`
- Regenerate Firebase config: `flutterfire configure` (uses `firebase.json`; project `restorent-pos-system`, writes `lib/firebase_options.dart` + platform `google-services.json`/`GoogleService-Info.plist`)

## Architecture

- App boots with `Firebase.initializeApp` in `lib/main.dart`, wrapped in `MultiProvider` with `CartProvider` (only provider).
- Firestore collections (field names are the contract — models in `lib/models/`):
  - `menu`: `name`, `description`, `price` (double), `imageUrl`, `category`
  - `orders`: `tableNumber`, `items` (list of `{menuItem, quantity}` maps), `totalAmount`, `status` (`pending` → `preparing` → `completed`), `createdAt` (Timestamp), `paymentId`
- Status updates happen directly in `lib/screens/pos/dashboard_screen.dart` via `FirebaseFirestore` doc updates.

## Gotchas

- `test/widget_test.dart` is stale counter-app boilerplate; it fails against the current `MyApp` and must be replaced with `MyApp`-based tests (which render `HomeScreen`, no Firebase needed) — don't treat it as a passing suite.
- `MenuScreen` uses hardcoded demo menu items whenever the Firestore `menu` collection is empty; a missing collection is not a bug.
- `lib/screens/pos/table_qr_screen.dart` has a placeholder QR base URL (`_baseUrl`, line 20). QR codes point at it; update before deploy.
- Currency is ₹ throughout; prices rendered with `toStringAsFixed(2)`.
- Password-free Firebase: emulator setup, auth, and payment (Razorpay placeholder in `CartProvider.placeOrder`) are not implemented.