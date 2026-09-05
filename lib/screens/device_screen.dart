// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/snackbar.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

// Alias for backwards compatibility
typedef DeviceScreenTest = DeviceScreen;

class _DeviceScreenState extends State<DeviceScreen> {
  // ESP32 BLE GATT UUIDs
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // BLE State
  int? _signalStrength;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  BluetoothCharacteristic? _displayCharacteristic;
  bool _isDiscoveringServices = false;
  bool _isSending = false;

  // Speech Recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _liveTranscript = "Tap the microphone to start listening...";
  PermissionStatus? _permissionStatus;

  // Subscriptions
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<int>? _mtuSubscription;

  @override
  void initState() {
    super.initState();
    _initBle();
    _initSpeech();
    _discoverServices();
  }

  void _initBle() {
    _connectionStateSubscription = widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = [];
        try {
          _signalStrength = await widget.device.readRssi();
        } catch (_) {}
      }
      if (mounted) setState(() {});
    });

    _mtuSubscription = widget.device.mtu.listen((value) {
      if (mounted) setState(() => _mtuSize = value);
    });
  }

  Future<void> _initSpeech() async {
    _permissionStatus = await Permission.microphone.request();
    if (_permissionStatus!.isDenied) {
      Snackbar.show(ABC.c, "Microphone permission is required for transcription", success: false);
      return;
    }

    _speechEnabled = await _speechToText.initialize(
      onError: (errorNotification) {
        debugPrint("Speech error: ${errorNotification.errorMsg}");
      },
      onStatus: (status) {
        if (mounted) setState(() {});
      },
    );

    if (!_speechEnabled) {
      Snackbar.show(ABC.c, "Speech recognition unavailable on this device", success: false);
    }
    if (mounted) setState(() {});
  }

  Future<void> _discoverServices() async {
    if (mounted) setState(() => _isDiscoveringServices = true);
    try {
      _services = await widget.device.discoverServices();
      for (final service in _services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
              _displayCharacteristic = char;
              break;
            }
          }
        }
      }
      if (_displayCharacteristic == null) {
        Snackbar.show(ABC.c, "OLED Display characteristic not found on device", success: false);
      } else {
        Snackbar.show(ABC.c, "Connected to Smart Glasses OLED Service!", success: true);
      }
    } catch (e) {
      Snackbar.show(ABC.c, "Service discovery error: $e", success: false);
    }
    if (mounted) setState(() => _isDiscoveringServices = false);
  }

  Future<void> _sendTextEsp(String text) async {
    if (_displayCharacteristic == null || _isSending) return;

    _isSending = true;
    try {
      // BLE standard default chunk size is 20 bytes unless MTU was negotiated
      final maxChunkSize = min(_mtuSize ?? 20, 20);
      for (var i = 0; i < text.length; i += maxChunkSize) {
        final chunk = text.substring(i, min(i + maxChunkSize, text.length));
        await _displayCharacteristic!.write(utf8.encode(chunk), withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 30));
      }
    } catch (e) {
      debugPrint("Send error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    if (text.isEmpty) return;

    setState(() {
      _liveTranscript = text;
    });

    _sendTextEsp(text);
  }

  void _toggleListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      if (_liveTranscript.isNotEmpty) {
        _sendTextEsp("\n");
      }
    } else {
      if (_permissionStatus?.isGranted ?? false) {
        await _speechToText.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(minutes: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        );
      } else {
        _initSpeech();
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _speechToText.stop();
    _connectionStateSubscription?.cancel();
    _mtuSubscription?.cancel();
    super.dispose();
  }

  bool get isConnected => _connectionState == BluetoothConnectionState.connected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.device.platformName.isNotEmpty ? widget.device.platformName : "Smart Glasses",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            Text(
              isConnected ? "Connected" : "Disconnected",
              style: TextStyle(
                fontSize: 12,
                color: isConnected ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        ),
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.speed, color: Colors.cyanAccent),
              tooltip: 'Request High MTU',
              onPressed: () async {
                try {
                  final newMtu = await widget.device.requestMtu(223);
                  if (mounted) setState(() => _mtuSize = newMtu);
                  Snackbar.show(ABC.c, "MTU set to $newMtu", success: true);
                } catch (e) {
                  Snackbar.show(ABC.c, "MTU request error: $e", success: false);
                }
              },
            ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isConnected ? Colors.greenAccent : Colors.white60,
            ),
            tooltip: 'Discover Services',
            onPressed: isConnected ? _discoverServices : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection & Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? Colors.teal.shade700 : Colors.red.shade900,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      color: isConnected ? Colors.tealAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _displayCharacteristic != null
                            ? "Display Ready (Transmitting live)"
                            : (isConnected ? "Scanning OLED characteristic..." : "Glasses disconnected"),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    if (_isDiscoveringServices || _isSending)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live Spectacle HUD Preview
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyanAccent.shade700, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "OLED SPECTACLE DISPLAY PREVIEW",
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _speechToText.isListening ? Colors.redAccent : Colors.white12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _speechToText.isListening ? "LIVE MIC" : "IDLE",
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.cyanAccent, height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          reverse: true,
                          child: Text(
                            _liveTranscript,
                            style: TextStyle(
                              fontSize: 22,
                              color: _speechToText.isListening ? Colors.white : Colors.white70,
                              height: 1.4,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Control Bar
              FloatingActionButton.extended(
                heroTag: "mic_fab",
                onPressed: _speechEnabled ? _toggleListening : _initSpeech,
                backgroundColor: _speechToText.isListening ? Colors.redAccent : const Color(0xFF00ADB5),
                icon: Icon(_speechToText.isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
                label: Text(
                  _speechToText.isListening ? "Stop Listening" : "Start Transcribing to Glasses",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
