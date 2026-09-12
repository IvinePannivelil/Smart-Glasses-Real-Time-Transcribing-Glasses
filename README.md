# 👓 Smart Glasses — Real-Time Transcribing Glasses

A real-time assistive hearing HUD for spectacles. The Flutter mobile app captures live ambient audio, transcribes speech-to-text in real time, and streams the live subtitles over Bluetooth Low Energy (BLE) to an ESP32 microcontroller mounted on glasses frames with an OLED micro-display.

---

## 📁 Project Structure

SmartGlasses_ListeningAid/
├── pubspec.yaml # Flutter project configuration & dependencies
├── README.md # Project overview & wiring diagram
├── android/ # Android native configuration
│ └── app/src/main/
│ └── AndroidManifest.xml # BLE + Audio permissions & Android 11+ STT queries
├── builds/ # Prebuilt binaries
│ └── listening_aid.apk # Build locally: flutter build apk (excluded from git)
├── firmware/ # Microcontroller source code
│ └── SmartGlasses_ESP32.ino # Arduino/C++ ESP32 BLE + OLED SSD1306 driver
└── lib/ # Flutter App Source Code
├── main.dart # Entrypoint & BLE state observer
├── screens/
│ ├── bluetooth_off_screen.dart # Prompt to enable Bluetooth
│ ├── scan_screen.dart # Device discovery list
│ └── device_screen.dart # Real-time Speech-to-Text & BLE transmitter
├── widgets/
│ ├── characteristic_tile.dart
│ ├── descriptor_tile.dart
│ ├── scan_result_tile.dart
│ ├── service_tile.dart
│ └── system_device_tile.dart
└── utils/
├── extra.dart # BLE extensions & stream helpers
├── snackbar.dart # Feedback snackbar alerts
└── utils.dart # Re-emitting stream transformers


---

## 🔌 Hardware Wiring Diagram

| OLED Pin (SSD1306) | ESP32 Pin   | Function       |
| ------------------ | ----------- | -------------- |
| **VCC**            | **3.3V**    | Power Supply   |
| **GND**            | **GND**     | Ground         |
| **SDA**            | **GPIO 21** | I2C Data Line  |
| **SCL**            | **GPIO 22** | I2C Clock Line |

---

## ⚙️ BLE GATT Service Specification

- **Advertised Name**: `ESP32 OLED Display`
- **Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID**: `beb5483e-36e1-4688-b7f5-ea07361b26a8` (Write / WriteWithoutResponse / Read / Notify)

---

## 🚀 How to Run

1. **ESP32 Firmware**: Open `firmware/SmartGlasses_ESP32.ino` in Arduino IDE or VSCode PlatformIO. Install `Adafruit SSD1306` and `Adafruit GFX Library`, then flash to your ESP32.
2. **Flutter App**: Run `flutter pub get` then `flutter run` on an Android device. To build a standalone APK, run `flutter build apk` — the output will be in `build/app/outputs/flutter-apk/`.
3. **Usage**:
   - Turn on Bluetooth on your phone.
   - Scan and tap **ESP32 OLED Display**.
   - Tap the microphone button on the screen and speak; live subtitles will appear directly on the OLED mounted to your spectacles.

---

## 👤 My Contribution

This was my main college project, built with a small team.

- I managed the overall execution of the project and originated the core concept of reflecting the OLED output onto a transparent lens to create the see-through HUD effect.
- I built the entire Flutter mobile application myself — BLE communication, permissions handling, and real-time speech-to-text integration.
- Hardware enclosure and physical spec design: teammate's contribution.
- ESP32 firmware: developed collaboratively.

---

## ⚠️ Known Limitations

This was tested and worked reliably during real conversational use — speech appeared on the HUD readably, line by line, in normal use. That said, a few edge cases are worth noting for anyone reviewing the code:

- **Long continuous speech**: The current firmware doesn't buffer/reassemble BLE chunks for very long, uninterrupted sentences — under sustained rapid speech with no natural pauses, only the most recent chunk would render. Normal conversational pacing (with pauses between sentences) is unaffected.
- **No text wrapping**: Very long lines can run past the visible OLED area; there's no scrolling or pagination yet.
- **Planned improvement**: A throttled ("leaky bucket" style) send pattern paired with full-message-per-send framing would resolve both of the above.

---

## 📸 App Screenshots

| Bluetooth Off | Scanning for Devices | Device Connected |
|---|---|---|
| [![Bluetooth Off](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/screenshots/bs.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/screenshots/bs.jpg) | [![Scanning](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/screenshots/scaning.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/screenshots/scaning.jpg) | [![Connected](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/screenshots/device%20connected.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/screenshots/device%20connected.jpg) |

| Waiting for Input | Listening (Mic Active) | Live Transcription |
|---|---|---|
| [![Waiting](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/screenshots/waiting%20for%20tr.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/screenshots/waiting%20for%20tr.jpg) | [![Listening](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/screenshots/starttranscription.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/screenshots/starttranscription.jpg) | [![Transcription](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/screenshots/transcription.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/screenshots/transcription.jpg) |

---

## 🔧 Hardware Build

### Circuit Diagram

[![Circuit Diagram](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/hardware/CIRCUIT%20DIAGRAM%20(3).png)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/hardware/CIRCUIT%20DIAGRAM%20(3).png)

### Prototype & Design Sketch

| Physical Prototype (Early Build) | Design Sketch with Dimensions |
|---|---|
| [![Glasses with HUD](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/hardware/transcribeglass%20(2).png)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/hardware/transcribeglass%20(2).png) | [![Design Sketch](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/hardware/IMG-20250205-WA0121.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/hardware/IMG-20250205-WA0121.jpg) |

### Final Build — OLED HUD in Action

| OLED displaying "hello hello" on ESP32 | Full enclosure with OLED lit | Glasses HUD view |
|---|---|---|
| [![OLED Demo](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/hardware/display.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/hardware/display.jpg) | [![Final Build](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/hardware/finalres2.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/hardware/finalres2.jpg) | [![Glasses HUD](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/hardware/WhatsApp%20Image%202025-03-19%20at%2011.47.11_aebcdcd8.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/hardware/WhatsApp%20Image%202025-03-19%20at%2011.47.11_aebcdcd8.jpg) |

| Final Device on desk |
|---|
| [![Final Result](https://github.com/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/raw/main/docs/hardware/finalres4.jpg)](/IvinePannivelil/Smart-Glasses-Real-Time-Transcribing-Glasses/blob/main/docs/hardware/finalres4.jpg) |
