# Restorent POS System

Flutter restaurant QR-ordering + POS app. Customers scan a table QR code, browse the menu, and place orders; reception/admin track and update order status in real time. Backend: Firebase (Cloud Firestore).

## Access (deployed)

- **Customer app** (scan QR → menu for your table): `https://restorent-pos-system.web.app`
- **POS app** (reception/admin): `https://restorent-pos-system.web.app/pos/`

Both are deployed automatically by GitHub Actions on every push to `main`.

## Running locally

Prerequisites: Flutter (stable), Firebase project config (already generated in `lib/firebase_options.dart`).

```bash
flutter pub get

# Customer web app (lib/main.dart)
flutter run -d chrome

# POS web app (lib/main_pos.dart) — separate terminal
flutter run -d chrome -t lib/main_pos.dart
```

To test the QR deep link locally, append `?table=4` to the customer app's URL (printed by `flutter run`) and refresh — it opens the menu for Table 4.

Orders placed in the customer app appear instantly in the POS app's Pending tab (live Firestore stream). Advance them: Pending → Preparing → Completed.

## Building for production

```bash
flutter build web                                # customer app → build/web
flutter build web --output build/web_pos \
  --target lib/main_pos.dart --base-href=/pos/   # POS app → build/web_pos
flutter build apk --target=lib/main_pos.dart     # POS app (Android)
```

## Notes & gotchas

- The menu shows hardcoded demo items until the Firestore `menu` collection is populated — a missing collection is not a bug.
- First POS dashboard run requires creating a Firestore composite index on `orders` (link appears in the console error).
- Firestore rules currently allow public read/write — tighten before public use.
- Table QR codes encode `https://restorent-pos-system.web.app/menu?table=<n>`; change `_baseUrl` in `lib/screens/pos/table_qr_screen.dart` together with the domain.
- Currency is ₹ throughout.
