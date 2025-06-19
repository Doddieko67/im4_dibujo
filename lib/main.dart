import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'features/auth/screens/splash_screen.dart'; // Asegúrate de que el path es correcto

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const OrigamiApp());
}

class OrigamiApp extends StatelessWidget {
  const OrigamiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mundo Origami',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'OrigamiFont',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // ✅ Este cambio muestra el formulario
    );
  }
}
