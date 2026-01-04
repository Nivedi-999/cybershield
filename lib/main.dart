// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'auth_provider.dart';
import 'dashboard.dart';
import 'vault_screen.dart';
import 'onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  const secureStorage = FlutterSecureStorage();
  String? encKeyString = await secureStorage.read(key: 'hive_enc_key');
  if (encKeyString == null) {
    final key = Hive.generateSecureKey();
    encKeyString = base64UrlEncode(key);
    await secureStorage.write(key: 'hive_enc_key', value: encKeyString);
  }
  final encKey = base64Url.decode(encKeyString);

  await Hive.openBox('vault', encryptionCipher: HiveAesCipher(encKey));

  final prefs = await SharedPreferences.getInstance();
  final isSetupComplete = prefs.getBool('setup_complete') ?? false;

  runApp(MyApp(isSetupComplete: isSetupComplete));
}

class MyApp extends StatelessWidget {
  final bool isSetupComplete;
  const MyApp({required this.isSetupComplete, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'CyberShield',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: Colors.cyan,
        ),
        home: isSetupComplete ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  static const List<Widget> _pages = [
    DashboardScreen(),
    LockedVaultScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}