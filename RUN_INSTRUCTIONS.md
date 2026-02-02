# How to Run "SaraFun" - Step-by-Step Guide

## 1. Prerequisites
Ensure you have the following installed:
- **Flutter SDK**: [Download & Install](https://docs.flutter.dev/get-started/install/windows) using PowerShell.
- **Chrome Browser**: For testing the Web App.

## 2. Setup Dependencies
Open your terminal (PowerShell or Command Prompt) and navigate to the project folder:
```powershell
cd "c:\Users\Huawei MadeBook XPro\OneDrive\Документы\SaraFun Antigravity\sara_fun"
flutter pub get
```

## 3. Run the App
To launch the app in your Chrome browser:
```powershell
flutter run -d chrome --web-renderer html
```
*Note: We use `--web-renderer html` for better compatibility with some image assets during development, but default is also fine.*

## 4. Troubleshooting "Firebase"
If the app shows "Permission Denied" errors when you try to create a Deal or Service:
It means the Security Rules were not deployed successfully.

**To deploy them manually:**
1.  Ensure you have `firebase.exe` in the `sara_fun` folder.
2.  **Login**: Run `.\firebase.exe login` and follow the browser prompt.
3.  **Deploy**:
    ```powershell
    .\firebase.exe deploy --only firestore:rules
    ```
    *(If this fails, let me know the error!)*

## 5. How to Test (Walkthrough)
Once the app is running in Chrome:
1.  **Login**: You will be automatically logged in as a "Master" (Partner) or "Client" based on the dummy logic in `main.dart` / `router.dart`.
    - *Default is set to Client or Master?* I set the router to start at `/business` (Master Dashboard) or `/scanner` depending on your last edit. You can change `initialLocation` in `lib/router.dart`.
2.  **Master Dashboard**:
    - Click the **+** button to add a Service (Title: "Test", Price: 100).
    - It should appear in the list.
3.  **Scan & Pay**:
    - Click **Scan Client QR**.
    - Click **Simulate Scan (Web Debug)**.
    - Enter a price (e.g., 500 Stars).
    - Click **Process Transaction**.
    - Watch for the "Deal Successful" message!

## 6. Development Tips
- **Hot Restart**: Press `R` (shift+r) in the terminal to reload the app instantly after code changes.
- **VS Code**: If you use VS Code, you can press **F5** to run the app if you open the `sara_fun` folder.
