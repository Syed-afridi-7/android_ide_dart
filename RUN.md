# 📱 How to Run `android_ide` (Wired & Wireless Setup Guide)

This guide provides step-by-step instructions to set up, build, and run the **`android_ide`** Flutter application on physical Android devices (via USB or Wi-Fi) and Android Emulators, along with running the **Cloud Terminal Backend**.

---

## 📋 Prerequisites

Before running the application, ensure you have installed:

1. **Flutter SDK** (v3.19.0 or higher) → `flutter doctor`
2. **Android SDK & Platform Tools** (`adb`)
3. **Node.js** (v18.0.0 or higher) → for running the Cloud/SSH Terminal backend
4. **Git**

---

## 🖥️ Step 1: Start the Cloud Terminal Backend

The app features a **Cloud & SSH Terminal Engine**. You must run the backend server on your local machine or a cloud host so the mobile app can stream terminal commands over WebSockets.

```bash
# Navigate to the server folder inside the project
cd server

# Install Node.js dependencies
npm install

# Start the server (runs on http://0.0.0.0:8080)
node server.js
```

> 💡 **Find Your Local Computer IP Address**:
> - **Windows**: Open Command Prompt and run `ipconfig` (look for *IPv4 Address*, e.g., `192.168.1.15`).
> - **macOS / Linux**: Run `ifconfig` or `ip a` (look for `wlan0` or `en0`).

---

## 🔌 Method 1: Wired Connection (USB Debugging)

This is the standard, most reliable way to run and debug the app on a physical Android device.

### 1. Enable USB Debugging on Your Android Device
1. Open **Settings** on your Android phone.
2. Go to **About Phone** → Tap **Build Number** 7 times until you see `"You are now a developer!"`.
3. Go back to **Settings** → **System** → **Developer Options**.
4. Enable **USB Debugging**.

### 2. Connect Your Phone to Your Computer
1. Plug your phone into your computer using a USB data cable.
2. A popup will appear on your phone screen: *"Allow USB debugging?"*.
3. Check **"Always allow from this computer"** and tap **Allow**.

### 3. Verify ADB Connection
Open your terminal on your computer and run:
```bash
adb devices
```
**Expected Output:**
```text
List of devices attached
e3b0c44298fc1c14    device
```

### 4. Run the Flutter App
Run the following command in the root project directory (`D:\android_ide_dart`), replacing `<YOUR_LOCAL_IP>` with your computer's IP address:

```bash
flutter run --dart-define=CLOUD_TERMINAL_URL=ws://<YOUR_LOCAL_IP>:8080
```

*Example:*
```bash
flutter run --dart-define=CLOUD_TERMINAL_URL=ws://192.168.1.15:8080
```

---

## 📶 Method 2: Wireless Connection (Wi-Fi ADB Debugging)

Run and debug your Flutter app without any physical cables plugged into your computer.

---

### Option A: Android 11+ (Native Wi-Fi Pairing — Recommended)

#### Requirements:
- Android 11 or higher on your phone.
- Computer and phone connected to the **SAME Wi-Fi network**.

#### Step-by-Step Instructions:

1. **Enable Wireless Debugging on Phone**:
   - Go to **Settings** → **Developer Options**.
   - Turn on **Wireless Debugging**.
   - Tap on **Wireless Debugging** (the text, not the switch) to open its detail screen.

2. **Pair Device via Pairing Code**:
   - On your phone, tap **"Pair device with pairing code"**.
   - A popup will show:
     - **Wi-Fi Pairing Code** (e.g., `123456`)
     - **IP Address & Port** (e.g., `192.168.1.150:38291`)

3. **Execute ADB Pair Command on Computer**:
   ```bash
   adb pair 192.168.1.150:38291
   ```
   When prompted, enter the 6-digit **Pairing Code**:
   ```text
   Enter pairing code: 123456
   Successfully paired to 192.168.1.150:38291
   ```

4. **Connect ADB to Device**:
   - On the phone's **Wireless Debugging** main screen, look at the main **IP address & Port** (Note: the port here is different from the pairing port, e.g., `192.168.1.150:41233`).
   - Run the connect command:
     ```bash
     adb connect 192.168.1.150:41233
     ```
   **Expected Output:**
   ```text
   connected to 192.168.1.150:41233
   ```

5. **Verify Connection**:
   ```bash
   adb devices
   ```
   **Output:**
   ```text
   List of devices attached
   192.168.1.150:41233    device
   ```

6. **Run the App Wirelessly**:
   ```bash
   flutter run --dart-define=CLOUD_TERMINAL_URL=ws://<YOUR_LOCAL_IP>:8080
   ```

---

### Option B: Android 10 and Below (Using Initial USB Setup)

1. Connect your phone via USB cable once.
2. Ensure both phone and PC are on the **SAME Wi-Fi network**.
3. Set ADB to TCP/IP port 5555:
   ```bash
   adb tcpip 5555
   ```
4. Disconnect the USB cable.
5. Find your phone's IP address (Settings → About Phone → Status → IP Address).
6. Connect via Wi-Fi:
   ```bash
   adb connect <PHONE_IP_ADDRESS>:5555
   ```
   *Example:* `adb connect 192.168.1.50:5555`
7. Run the Flutter app:
   ```bash
   flutter run --dart-define=CLOUD_TERMINAL_URL=ws://<YOUR_LOCAL_IP>:8080
   ```

---

## 💻 Method 3: Android Emulator (Virtual Device)

If you are running on an official Android Studio Emulator:

1. Launch your Android Emulator from Android Studio or VS Code.
2. The Emulator automatically uses `10.0.2.2` to access your computer's `localhost`.
3. Run the app:
   ```bash
   flutter run
   ```
   *(Default `CLOUD_TERMINAL_URL` fallback is `ws://10.0.2.2:8080`)*

---

## 🛠️ Summary Command Reference

| Action | Command |
|--------|---------|
| Start Backend Server | `cd server && node server.js` |
| List ADB Devices | `adb devices` |
| Pair Wi-Fi ADB (Android 11+) | `adb pair <PHONE_IP>:<PAIR_PORT>` |
| Connect Wi-Fi ADB | `adb connect <PHONE_IP>:<PORT>` |
| Disconnect Wi-Fi ADB | `adb disconnect` |
| Run Flutter (Local IP) | `flutter run --dart-define=CLOUD_TERMINAL_URL=ws://<IP>:8080` |
| Run Flutter (Cloud Host) | `flutter run --dart-define=CLOUD_TERMINAL_URL=wss://your-app.onrender.com` |
| Static Code Analysis | `flutter analyze` |

---

## ❓ Troubleshooting & FAQs

### Q: The terminal inside the app shows "Connecting..." and fails.
1. Make sure `node server.js` is running on your computer.
2. Ensure your phone and computer are connected to the **SAME Wi-Fi network**.
3. Check your computer's Firewall settings (allow incoming traffic on port `8080`).

### Q: `adb devices` shows `unauthorized`.
- Unlock your phone and look for the *"Allow USB debugging?"* prompt. Tap **Allow**.
- If stuck, run `adb kill-server && adb start-server` and reconnect.
