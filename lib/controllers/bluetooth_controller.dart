import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/bluetooth_service.dart';

enum BluetoothStatus { idle, scanning, connecting, connected, error }

class BluetoothController extends ChangeNotifier {
  late BluetoothService _btService;

  List<BluetoothDevice> _bondedDevices = [];
  BluetoothDevice? _connectedDevice;
  UserModel? _remoteUser;
  final List<MessageModel> _messages = [];
  BluetoothStatus _status = BluetoothStatus.idle;
  String? _errorMessage;
  UserModel? _localUser;

  List<BluetoothDevice> get bondedDevices => List.unmodifiable(_bondedDevices);
  BluetoothDevice? get connectedDevice => _connectedDevice;
  UserModel? get remoteUser => _remoteUser;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  BluetoothStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == BluetoothStatus.connected;

  void setLocalUser(UserModel user) {
    _localUser = user;
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  Future<void> loadBondedDevices() async {
    _status = BluetoothStatus.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      await requestPermissions();
      final devices =
      await FlutterBluetoothSerial.instance.getBondedDevices();
      _bondedDevices = devices;
      _status = BluetoothStatus.idle;
    } catch (e) {
      _errorMessage = 'Failed to load devices: $e';
      _status = BluetoothStatus.error;
    }

    notifyListeners();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    _status = BluetoothStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      _btService = BluetoothService(
        onPacketReceived: _handlePacket,
        onDisconnected: _handleDisconnected,
      );

      await _btService.connect(device);
      _connectedDevice = device;
      _status = BluetoothStatus.connected;
      _messages.clear();
      notifyListeners();

      // Send handshake immediately
      await _sendHandshake();
      return true;
    } catch (e) {
      _errorMessage = 'Connection failed: $e';
      _status = BluetoothStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> _sendHandshake() async {
    if (_localUser == null) return;
    final packet = BtPacket(
      type: BtPacketType.handshake,
      payload: _localUser!.toPublicMap(),
    );
    await _btService.sendPacket(packet);
  }

  Future<void> sendMessage(String content) async {
    if (!isConnected || content.trim().isEmpty || _localUser == null) return;

    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: _localUser!.id,
      senderName: _localUser!.name,
      content: content.trim(),
      timestamp: DateTime.now(),
      isMe: true,
    );

    final packet = BtPacket(
      type: BtPacketType.message,
      payload: message.toMap(),
    );

    await _btService.sendPacket(packet);
    _messages.add(message);
    notifyListeners();
  }

  void _handlePacket(BtPacket packet) {
    switch (packet.type) {
      case BtPacketType.handshake:
        _remoteUser = UserModel(
          id: packet.payload['id'] as String,
          name: packet.payload['name'] as String,
          username: '',
          passwordHash: '',
        );
        notifyListeners();
        break;

      case BtPacketType.message:
        final message = MessageModel.fromMap(packet.payload, isMe: false);
        _messages.add(message);
        notifyListeners();
        break;
    }
  }

  void _handleDisconnected() {
    _status = BluetoothStatus.idle;
    _connectedDevice = null;
    _remoteUser = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _btService.disconnect();
    _handleDisconnected();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
