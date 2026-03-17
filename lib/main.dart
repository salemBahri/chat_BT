import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/bluetooth_controller.dart';
import 'controllers/profile_controller.dart';
import 'services/local_storage_service.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/chat/chat_view.dart';
import 'views/devices/devices_view.dart';
import 'views/profile/profile_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await LocalStorageService.create();
  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  final LocalStorageService storage;
  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(storage),
        ),
        ChangeNotifierProxyProvider<AuthController, ProfileController>(
          create: (ctx) => ProfileController(
            storage,
            ctx.read<AuthController>(),
          ),
          update: (_, auth, prev) =>
          prev ?? ProfileController(storage, auth),
        ),
        ChangeNotifierProvider(
          create: (_) => BluetoothController(),
        ),
      ],
      child: MaterialApp(
        title: 'BT Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: _resolveInitialRoute(storage),
        routes: {
          AppRoutes.login: (_) => const LoginView(),
          AppRoutes.register: (_) => const RegisterView(),
          AppRoutes.devices: (_) => const DevicesView(),
          AppRoutes.chat: (_) => const ChatView(),
          AppRoutes.profile: (_) => const ProfileView(),
        },
      ),
    );
  }

  String _resolveInitialRoute(LocalStorageService storage) {
    return storage.isLoggedIn ? AppRoutes.devices : AppRoutes.login;
  }
}
