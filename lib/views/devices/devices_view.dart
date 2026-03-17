import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import '../../controllers/bluetooth_controller.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class DevicesView extends StatefulWidget {
  const DevicesView({super.key});

  @override
  State<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends State<DevicesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothController>().loadBondedDevices();
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    final bt = context.read<BluetoothController>();
    final success = await bt.connectToDevice(device);
    if (!mounted) return;
    if (success) {
      Navigator.pushNamed(context, AppRoutes.chat);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bt.errorMessage ?? 'Connection failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            tooltip: 'Profile',
          ),
          Consumer<BluetoothController>(
            builder: (_, bt, __) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: bt.status == BluetoothStatus.scanning
                  ? null
                  : bt.loadBondedDevices,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Consumer<BluetoothController>(
        builder: (_, bt, __) {
          if (bt.status == BluetoothStatus.scanning ||
              bt.status == BluetoothStatus.connecting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    bt.status == BluetoothStatus.connecting
                        ? 'Connecting...'
                        : 'Loading devices...',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (bt.bondedDevices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_disabled,
                      size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'No paired devices found.\nPair devices in Bluetooth settings first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        FlutterBluetoothSerial.instance.openSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Open BT Settings'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bt.bondedDevices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final device = bt.bondedDevices[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFDADCE0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text(
                    device.name ?? 'Unknown Device',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    device.address,
                    style:
                    const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _connect(device),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Connect'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
