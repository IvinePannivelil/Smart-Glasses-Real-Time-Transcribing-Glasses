/*
 * Smart Glasses / Listening Aid - ESP32 BLE + OLED Firmware
 * 
 * Hardware:
 * - ESP32 Development Board (ESP32-WROOM-32 / NodeMCU ESP32)
 * - 0.96" or 0.91" I2C OLED Display (SSD1306 Driver)
 * 
 * Wiring:
 * - OLED VCC -> ESP32 3.3V
 * - OLED GND -> ESP32 GND
 * - OLED SDA -> ESP32 GPIO 21
 * - OLED SCL -> ESP32 GPIO 22
 */

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
#define SCREEN_ADDRESS 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Exact BLE UUIDs matching Flutter Client
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

String currentText = "Waiting for speech...";

void renderDisplay(const String& text, bool isConnected) {
  display.clearDisplay();
  
  // Header / Status bar
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print(isConnected ? "[CONNECTED]" : "[DISCONNECTED]");
  display.setCursor(95, 0);
  display.print("HUD");
  display.drawLine(0, 9, 127, 9, SSD1306_WHITE);
  
  // Subtitle / Transcription Body
  display.setTextSize(1);
  display.setCursor(0, 14);
  display.println(text);
  
  display.display();
}

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println(">> Phone Connected!");
      renderDisplay("Phone Connected!\nListening...", true);
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println(">> Phone Disconnected!");
      renderDisplay("Disconnected.\nWaiting for app...", false);
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        String incoming = "";
        for (int i = 0; i < rxValue.length(); i++) {
          incoming += rxValue[i];
        }
        
        Serial.print("Received Speech: ");
        Serial.println(incoming);
        
        currentText = incoming;
        renderDisplay(currentText, true);
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Smart Glasses ESP32 BLE Server...");

  // Initialize I2C and OLED
  Wire.begin(21, 22);
  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed!"));
    for (;;);
  }

  display.clearDisplay();
  display.display();
  renderDisplay("Initializing BLE...", false);

  // Initialize BLE
  BLEDevice::init("ESP32 OLED Display");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create Characteristic
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_WRITE_NR
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());

  // Start Service
  pService->start();

  // Start Advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE Device Ready. Advertising as 'ESP32 OLED Display'");
  renderDisplay("Ready to pair\nwith phone app.", false);
}

void loop() {
  // Handle BLE re-advertising on disconnect
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Restarted BLE advertising...");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  delay(20);
}
