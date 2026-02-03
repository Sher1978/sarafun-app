# TECH_STACK_LOCK.md
> 🔒 **CONFIGURATION FROZEN: DO NOT MODIFY WITHOUT ARCHITECT APPROVAL**
> **Last Verification:** 2026-02-03 (Green Build)
> **Status:** STABLE

This file serves as the **Single Source of Truth** for the SaraFun project configuration. Any deviation from these versions or rules requires a formal migration plan.

## 1. Critical Versions (DO NOT UPGRADE)

| Component | Version Constraint | Notes |
| :--- | :--- | :--- |
| **Flutter SDK** | `3.38.x` (Stable) | 2026 Compatible Bundle |
| **Dart SDK** | `>=3.2.0 <4.0.0` | Strict typing enabled |
| **Riverpod** | `^3.1.0` | **NO `StateProvider`**. Use `NotifierProvider`. |
| **GoRouter** | `^17.0.1` | - |
| **Firebase** | `^4.4.0` (Core) | Compatible with web compilation |
| **Telegram Web App** | `^0.3.3` | Legacy package, use `dart:js_util` for interop |
| **Node.js** | `20.x` | Required for Cloud Functions deployment |

## 2. Build & Deploy Rules

### Web Build Command
```bash
flutter build web --release --base-href "/" --verbose
```
*   **Flag Requirement**: `--base-href "/"` is mandatory for custom domain (`app.sarafun.site`) routing.
*   **Artifacts**: distinct files must exist in `build/web`: `index.html`, `main.dart.js` (or `wasm`), `CNAME`.

### CI/CD Pipeline (GitHub Actions)
*   **Provider**: `actions/deploy-pages@v4` (Official)
*   **Path**: `build/web` (Hardcoded)
*   **Sanity Check**: MUST verify `test -f build/web/index.html` before deploy step.

## 3. Known Fixes (IMMUTABLE - DO NOT REVERT)

### A. Riverpod 3.0 Compatibility
*   **ISSUE**: `StateProvider` was removed.
*   **RULE**: All simple state must be managed via `NotifierProvider` / `Notifier`.
    *   ❌ `ref.read(provider.notifier).state = x`
    *   ✅ `ref.read(provider.notifier).update(x)` (Method call)

### B. AsyncValue Syntax
*   **ISSUE**: `.valueOrNull` is deprecated/removed in strict configurations.
*   **RULE**: Always use robust accessor:
    *   ❌ `asyncValue.valueOrNull`
    *   ✅ `asyncValue.asData?.value`

### C. Web Interop (Telegram Service)
*   **ISSUE**: `dart:js` causes compilation warnings/errors on modern SDKs.
*   **RULE**: Use `dart:js_util` for dynamic property access.
    *   ✅ `js_util.getProperty(window, 'Telegram')`

## 4. Discovery Screen Protocol
*   **Component**: `_CompactServiceCard` / `_CompactMasterCard`
*   **RULE**: Callbacks (like `onFavoriteToggle`) MUST be defined as `final` fields in the class body, not just passed to the constructor.

---
**Violation of these rules will cause immediate build failure.**
