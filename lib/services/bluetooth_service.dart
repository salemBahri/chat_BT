import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Packet types exchanged over BT
enum BtPacketType { handshake, message }

class BtPacket {
  final BtPacketType type;
  final Map<String, dynamic> payload;

  BtPacket({required this.type, required this.payload});

  String encode() {
    final map = {
      'type': type.name,
      'payload': payload,
    };
    return '${jsonEncode(map)}\n'; // newline as frame delimiter
  }

  factory BtPacket.decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return BtPacket(
      type: BtPacketType.values.byName(map['type'] as String),
      payload: map['payload'] as Map<String, dynamic>,
    );
  }
}

class BluetoothService {
  BluetoothConnection? _connection;
  String _buffer = '';

  final void Function(BtPacket packet) onPacketReceived;
  final void Function() onDisconnected;

  BluetoothService({
    required this.onPacketReceived,
    required this.onDisconnected,
  });

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    _connection = await BluetoothConnection.toAddress(device.address);
    _listenToIncoming();
  }

  void _listenToIncoming() {
    _connection!.input!.listen(
          (Uint8List data) {
        _buffer += utf8.decode(data);
        // Process all complete frames (newline delimited)
        while (_buffer.contains('\n')) {
          final idx = _buffer.indexOf('\n');
          final frame = _buffer.substring(0, idx).trim();
          _buffer = _buffer.substring(idx + 1);
          if (frame.isNotEmpty) {
            try {
              final packet = BtPacket.decode(frame);
              onPacketReceived(packet);
            } catch (_) {}
          }
        }
      },
      onDone: () {
        disconnect();
        onDisconnected();
      },
      onError: (_) {
        disconnect();
        onDisconnected();
      },
    );
  }

  Future<void> sendPacket(BtPacket packet) async {
    if (_connection == null || !_connection!.isConnected) return;
    _connection!.output.add(Uint8List.fromList(utf8.encode(packet.encode())));
    await _connection!.output.allSent;
  }

  void disconnect() {
    _buffer = '';
    _connection?.dispose();
    _connection = null;
  }

  bool get isConnected => _connection?.isConnected ?? false;
}
