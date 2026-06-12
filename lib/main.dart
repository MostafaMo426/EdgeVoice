import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'providers/device_pairing_provider.dart';
import 'providers/edgevoice_voice_provider.dart';

// --- HTTP OVERRIDES FOR NGROK (Mobile/Desktop only) ---
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: dart:io's HttpOverrides will CRASH on Web
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }
  
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => DevicePairingProvider()),
        ChangeNotifierProxyProvider<DevicePairingProvider, EdgeVoiceVoiceProvider>(
          create: (_) => EdgeVoiceVoiceProvider(),
          update: (_, pairing, voice) => voice!..updatePairingProvider(pairing),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Home App',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.black)),
            );
          }
          if (snapshot.hasError) {
             return Scaffold(body: Center(child: Text("Startup Error: ${snapshot.error}")));
          }
          if (snapshot.data == true) {
            return const HomeScreen();
          }
          return const WelcomeScreen();
        },
      ),
    );
  }
}