# 👓 Smart Glasses / Listening Aid Project

A real-time assistive hearing HUD for spectacles. The Flutter mobile app captures live ambient audio, transcribes speech-to-text in real time, and streams the live subtitles over Bluetooth Low Energy (BLE) to an ESP32 microcontroller mounted on glasses frames with an OLED micro-display.

---

## 📁 Project Structure

```
SmartGlasses_ListeningAid/
├── pubspec.yaml               # Flutter project configuration & dependencies
├── README.md                  # Project overview & wiring diagram
├── android/                   # Android native configuration
│   └── app/src/main/
│       └── AndroidManifest.xml # BLE + Audio permissions & Android 11+ STT queries
├── builds/                    # Prebuilt binaries
│   └── listening_aid.apk      # Ready-to-install Android APK
├── firmware/                  # Microcontroller source code
│   └── SmartGlasses_ESP32.ino # Arduino/C++ ESP32 BLE + OLED SSD1306 driver
└── lib/                       # Flutter App Source Code
    ├── main.dart              # Entrypoint & BLE state observer
    ├── screens/
    │   ├── bluetooth_off_screen.dart # Prompt to enable Bluetooth
    │   ├── scan_screen.dart          # Device discovery list
    │   └── device_screen.dart        # Real-time Speech-to-Text & BLE transmitter
    ├── widgets/
    │   ├── characteristic_tile.dart
    │   ├── descriptor_tile.dart
    │   ├── scan_result_tile.dart
    │   ├── service_tile.dart
    │   └── system_device_tile.dart
    └── utils/
        ├── extra.dart         # BLE extensions & stream helpers
        ├── snackbar.dart      # Feedback snackbar alerts
        └── utils.dart         # Re-emitting stream transformers
```

---

## 🔌 Hardware Wiring Diagram

| OLED Pin (SSD1306) | ESP32 Pin | Function |
| :--- | :--- | :--- |
| **VCC** | **3.3V** | Power Supply |
| **GND** | **GND** | Ground |
| **SDA** | **GPIO 21** | I2C Data Line |
| **SCL** | **GPIO 22** | I2C Clock Line |

---

## ⚙️ BLE GATT Service Specification

- **Advertised Name**: `ESP32 OLED Display`
- **Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID**: `beb5483e-36e1-4688-b7f5-ea07361b26a8` (Write / WriteWithoutResponse / Read / Notify)

---

## 🚀 How to Run

1. **ESP32 Firmware**: Open `firmware/SmartGlasses_ESP32.ino` in Arduino IDE or VSCode PlatformIO. Install `Adafruit SSD1306` and `Adafruit GFX Library`, then flash to your ESP32.
2. **Flutter App**: Run `flutter pub get` and `flutter run` on an Android device (or install `builds/listening_aid.apk`).
3. **Usage**:
   - Turn on Bluetooth on your phone.
   - Scan and tap **ESP32 OLED Display**.
   - Tap the microphone button on the screen and speak; live subtitles will appear directly on the OLED mounted to your spectacles.
