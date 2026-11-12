# Product catalog API — Stage 1

> Historical Stage 1 notes. Current architecture, verification, and GitHub status
> are documented in the root README.md. Flutter integration and BLoC are now implemented.

This Express server belongs to the existing Flutter project in the parent folder.
It serves our own local JSON data; it does not call DummyJSON. The Flutter client
still uses its existing URL until the later integration stage.

## Start on Windows (PowerShell)

Node.js 22 or later is required for the scripts and built-in test runner.
Using `npm.cmd` also works when PowerShell blocks the `npm.ps1` script.

```powershell
cd C:\Users\LOG\Desktop\firstflutterproject_clean\firstflutterproject\server
npm.cmd ci
npm.cmd start
```

The API listens on `0.0.0.0:3000`. Stop it with Ctrl+C.
For automatic JavaScript reloads, use `npm.cmd run dev` instead.
The JSON file is loaded at startup; restart the server after editing product data.
To use another port: `$env:PORT = '3001'` before starting it.

## Manual verification

Run in a second PowerShell window while the server is running:

```powershell
Invoke-RestMethod http://localhost:3000/health
Invoke-RestMethod http://localhost:3000/api/products | ConvertTo-Json -Depth 10
Invoke-RestMethod http://localhost:3000/api/products/1 | ConvertTo-Json -Depth 10
curl.exe -i http://localhost:3000/api/products/999999
curl.exe -i http://localhost:3000/api/products/abc
```

| Endpoint | Response |
| --- | --- |
| `GET /health` | 200, `{ "status": "ok" }` |
| `GET /api/products` | 200, `{ "products": [...], "total": 8 }` |
| `GET /api/products/1` | 200, one product object |
| `GET /api/products/999999` | 404, `{ "error": "Product not found" }` |
| `GET /api/products/abc` | 400, JSON error for a malformed ID |

IDs must be positive safe integers. Unknown routes return a JSON 404.
This stage provides read-only endpoints without pagination or writes.

## Automated verification

```powershell
npm.cmd test
dart test/product_compatibility.dart
```

The Node tests start an isolated server on a free loopback port and stop it afterward.
They cover health, the list wrapper, all individual products, invalid/missing IDs,
unknown routes, local CORS/preflight, and every required nested field/type.
The Dart script imports the actual `lib/product.dart` model and parses/round-trips
all eight records without Flutter or extra packages.

## Data and local networking

`data/products.json` is a plain array with eight demonstration products. Every
record includes the fields consumed by `Product.fromJson`, including `dimensions`,
`reviews`, and `meta`. Prices are sample USD values; weights are kg and dimensions
are cm. Reviews, stock, brands, barcodes, and QR links are demonstration data.
Product images use external Unsplash URLs, so image loading needs internet access;
the API itself serves all product data from the local file. Image availability has
not been verified. QR links use example.com placeholders.

CORS permits HTTP browser origins on `localhost`, `127.0.0.1`, and `[::1]`, with
any local port, for GET/HEAD/OPTIONS. Credentials are not enabled. Other browser
origins receive no CORS permission. CORS is a browser rule, not authentication;
native clients can still call the API.

For later Flutter integration, the API base URL will be:

- Desktop/local browser: `http://localhost:3000/api`
- Android emulator: `http://10.0.2.2:3000/api`
- Physical phone on the same Wi-Fi: `http://<PC-LAN-IP>:3000/api`

Phone access may require a Windows firewall rule. Android HTTP configuration and
the Flutter URL change are deferred to the integration stage.

## Environment and checks performed on 2026-11-12

| Check | Observed result |
| --- | --- |
| Flutter | 3.47.5 stable; `flutter --version` succeeded |
| Dart | 3.13.4; `dart --version` succeeded |
| Node.js / npm | v24.11.1 / 11.6.2 |
| Android | SDK/build-tools 37.0.0; doctor passes; all licenses accepted |
| Java | Android Studio bundled OpenJDK 25.0.3 |
| ADB | 1.0.41, platform-tools 37.0.1; no attached Android devices |
| Emulator | Medium_Phone_API_37.0 configured; not started |
| Available Flutter targets | Windows, Chrome, Edge |
| Windows desktop builds | Blocked: Visual Studio with Desktop development with C++ is missing |
| `flutter analyze` / `flutter test` | Both attempted; dependency resolution blocks both because pubspec requires Dart `^3.13.5` |
| Backend dependency installation | Succeeded; Express 5.3.0 and CORS 2.8.6; lockfile included |
| `npm.cmd test` | 8 tests passed, 0 failed |
| JavaScript syntax | `node --check app.js` and `node --check index.js` succeeded |
| Actual server startup | `index.js` started on port 3000; all 3 required endpoints returned HTTP 200; server then stopped |
| Actual Dart model compatibility | All 8 products parsed and round-tripped successfully |

Initial restricted-environment attempts blocked SDK cache access, npm downloads,
and HTTP loopback connections. Installation, Flutter diagnostics, and API tests
were repeated successfully with the needed execution access. The plain Dart
compatibility script ran using the SDK's `dart.exe` directly.

The existing Flutter dependencies are Flutter, cupertino_icons, and Dio;
flutter_test and flutter_lints are development dependencies. No flutter_bloc
dependency or BLoC implementation was added. The existing counter widget test
appears outdated for the catalog UI, but could not execute due to the SDK mismatch.
No Flutter source files or dependency declarations were changed.

No `.git` directory was found in the workspace or Flutter project. No repository
was initialized and nothing was pushed. The existing Git invocation also reported
`fatal: cannot change to 'C:/Users/LOG'`; Git configuration was left untouched.

Only Express and CORS are runtime dependencies. Automated HTTP tests use Node's
built-in runner, assertions, and fetch. `node_modules` and the local npm cache are
ignored; commit `package-lock.json` with the server sources in a later stage.

Express reference: [official installation guide](https://expressjs.com/en/5x/starter/installing/).
