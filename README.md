# Flutter Product Catalog - Mobile Development Midterm

A cross-platform Flutter product catalog backed by our own Node.js Express REST
API. The application uses event-driven BLoC state management and local JSON
storage on the server.

## Features

- Browse eight sample products with images, prices, discounts, ratings, and stock.
- Open product details and return to the catalog.
- Loading indicator, helpful error message, Retry button, and empty-list state.
- Configurable backend URL for Android Emulator, web, desktop, or a physical phone.
- Automated Bloc, repository/API, widget, and backend tests.

## Technologies and requirements

Flutter, Dart, flutter_bloc, Dio, Node.js, and Express. CORS is configured for
local browser development.

- Flutter with Dart **3.13.4 or later, below 4.0.0**. Verified toolchain:
  Flutter 3.47.5 / Dart 3.13.4.
- Node.js **22 or later** and npm. Verified: Node.js 24.11.1 / npm 11.6.2.
- Android Studio, Android SDK, accepted Android licenses, and an Android emulator
  or USB-debugging-enabled phone for Android development.
- Git for source control. A GitHub account is required for submission.
- Chrome for optional web development. Native iOS/macOS builds require macOS and
  Xcode; Windows desktop builds require Visual Studio's C++ desktop workload.

## Project structure

```text
.
├── lib/
│   ├── bloc/
│   │   ├── product_bloc.dart
│   │   ├── product_event.dart
│   │   └── product_state.dart
│   ├── widgets/product_view.dart
│   ├── main.dart
│   ├── product.dart
│   ├── product_api.dart
│   ├── product_repository.dart
│   ├── product_page.dart
│   └── rest_api.dart
├── test/
│   ├── product_bloc_test.dart
│   ├── product_repository_test.dart
│   └── widget_test.dart
├── server/
│   ├── data/products.json
│   ├── test/
│   ├── app.js
│   ├── index.js
│   ├── package.json
│   └── package-lock.json
├── android/  ios/  web/  windows/  macos/  linux/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## Architecture

```text
Catalog UI -> ProductEvent -> ProductBloc -> ProductRepository
                                                |
                                         ProductApiImpl (Dio)
                                                |
                                  HTTP GET /api/products
                                                |
                                   Express -> products.json
                                                |
                                  JSON -> Product.fromJson
                                                |
                            ProductState -> BlocBuilder -> UI
```

Widgets do not make HTTP requests. The API client handles HTTP and JSON parsing;
the repository exposes product loading and translates network/data errors into
helpful failures. The Bloc handles asynchronous events and emits states.
BlocProvider owns the Bloc lifecycle, and BlocBuilder renders the catalog state.
The existing product-card design and details navigation are preserved.

### BLoC events and states

| Event | Purpose |
| --- | --- |
| LoadProducts | Request the catalog when the screen starts |
| RetryProducts | Make a new request after a failure |

| State | UI behavior |
| --- | --- |
| ProductInitial | Initial state before loading |
| ProductLoading | Display a progress indicator |
| ProductLoaded | Display the actual product list, or an empty-list message |
| ProductError | Display a helpful message and Retry button |

Both events use an awaited request handler. Concurrent load events are ignored
while a request is in progress, preventing duplicate requests.

## REST API

| Method | Endpoint | Response |
| --- | --- | --- |
| GET | /health | 200: `{"status":"ok"}` |
| GET | /api/products | 200: `{"products":[...],"total":8}` |
| GET | /api/products/:id | 200: one product object |

Malformed IDs return 400. Missing products and unknown routes return JSON 404
responses. Products include all fields required by the Flutter model, including
dimensions, reviews, and meta. The server reads its own JSON file at startup and
does not use DummyJSON. Restart it after editing product data.

This is a read-only demonstration API. Product images use external Unsplash URLs;
image loading requires internet access and has a fallback placeholder. Sample
reviews, brands, QR links, prices, and stock are demonstration data.

## Install dependencies

Open PowerShell in the project root (the folder containing pubspec.yaml):

```powershell
flutter pub get
Push-Location server
npm.cmd ci
Pop-Location
```

The committed lockfiles keep dependency installation reproducible. npm.cmd avoids
PowerShell execution-policy problems with npm.ps1.

## Start the Express backend

In one PowerShell window, from the project root:

```powershell
cd server
npm.cmd start
```

The server listens at http://localhost:3000 and accepts connections on all network
interfaces. Stop with Ctrl+C. Optional JavaScript watch mode: `npm.cmd run dev`.
To change the server port, set `$env:PORT = '3001'` before starting.

Verify from another window:

```powershell
Invoke-RestMethod http://localhost:3000/health
Invoke-RestMethod http://localhost:3000/api/products | ConvertTo-Json -Depth 10
Invoke-RestMethod http://localhost:3000/api/products/1 | ConvertTo-Json -Depth 10
```

## Launch Flutter on Android Emulator

With the backend running, open another PowerShell window in the project root:

```powershell
flutter emulators
flutter emulators --launch Medium_Phone_API_37.0
flutter devices
```

Use your installed emulator ID if it differs. After boot, replace ANDROID_DEVICE_ID
below with the ID reported by flutter devices:

```powershell
flutter run -d ANDROID_DEVICE_ID --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Android Emulator uses 10.0.2.2 to reach the development computer. The debug manifest
permits local HTTP. Release builds should use HTTPS.

## API_BASE_URL configuration

The value is the server origin **without /api**; the client adds /api/products.

| Target | Example API_BASE_URL |
| --- | --- |
| Android Emulator (default) | http://10.0.2.2:3000 |
| Browser / desktop on the server computer | http://localhost:3000 |
| Physical Android phone on the same Wi-Fi | http://PC_LAN_IP:3000 |

For web development:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

For a physical phone, replace PC_LAN_IP with your computer's LAN IP and permit the
backend through the local firewall if required. CORS permits HTTP localhost,
127.0.0.1, and IPv6 loopback browser origins with variable local ports. Native
mobile requests are not subject to browser CORS. Restart/rebuild the Flutter app
after changing a dart-define.

## Tests and final review

Run from the project root:

```powershell
flutter analyze
flutter test
npm.cmd test --prefix server
dart server/test/product_compatibility.dart
```

Final review on 2026-11-12: analysis reported no issues, all **12 Flutter tests**
and **8 backend tests** passed. The standalone Dart check parsed and round-tripped
all eight records through the actual Product.fromJson model.

Flutter tests cover successful loading, failure, retry, overlapping requests,
empty results, configured endpoints, nested JSON parsing, loading/error UI, and
details navigation. Backend tests cover all endpoints, invalid/missing IDs,
CORS/preflight, and required data fields. Tests run against isolated test servers
or test doubles; they do not require a manually started backend.

Android catalog loading, backend communication, and details navigation have been
confirmed by the project owner. This review reran automated tests; it did not
repeat the Android runtime demonstration.

## University requirements

| Requirement | Implementation / status |
| --- | --- |
| Flutter cross-platform mobile application | Existing Flutter app with Android, iOS, web, and desktop platform projects; Android demonstrated |
| Communication with a server | Dio requests our Express REST API over HTTP; JSON is parsed into Product objects |
| GitHub repository containing the project | Local Git repository includes Flutter and server sources; publication is pending repository/visibility confirmation |
| BLoC state management | ProductBloc extends Bloc<ProductEvent, ProductState>, using LoadProducts and RetryProducts with explicit states |

Platform project availability does not imply every platform has been runtime-tested.

## GitHub submission

The project is prepared for a single repository containing both Flutter and
server code. Generated builds, dependency directories, browser profiles, local
configuration, and secrets are excluded by .gitignore. Required source files,
platform projects, assets, and dependency lockfiles are retained.

No remote URL is assumed and nothing has been pushed. Choose the GitHub repository
name and visibility, then confirm the actual remote URL before publishing. Create
an empty repository without an additional README or initial commit to avoid
conflicting histories. GitHub CLI is optional; Git over HTTPS or SSH also works.
