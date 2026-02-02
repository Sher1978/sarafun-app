# Install Flutter SDK

It seems **Flutter is not installed** on your computer. You need it to run the app.

## Step 1: Download
1.  Go to the [official Flutter Windows install page](https://docs.flutter.dev/get-started/install/windows).
2.  Download the **Stable Channel** zip file (approx 1GB).

## Step 2: Extract
1.  Extract the zip file to a clean folder, for example: `C:\src\flutter`.
    *Warning: Do not install it in "Program Files" due to permission issues.*

## Step 3: Update Path
1.  Press **Win** key, type "env", and select **Edit the system environment variables**.
2.  Click **Environment Variables**.
3.  Under **User variables**, select **Path** and click **Edit**.
4.  Click **New** and add the path to the bin folder:
    `C:\src\flutter\bin`
5.  Click **OK** on all windows.

## Step 4: Verify
1.  **Restart** your terminal (close VS Code and reopen).
2.  Run: `flutter doctor`
3.  If it works, run the app: `flutter run -d chrome`.
