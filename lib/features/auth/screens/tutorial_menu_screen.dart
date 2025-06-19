import 'package:flutter/material.dart';
import 'tutoriales_screen.dart';  // Importa el archivo de pantalla de tutoriales

class TutorialMenuScreen extends StatefulWidget {
  const TutorialMenuScreen({Key? key}) : super(key: key);

  @override
  State<TutorialMenuScreen> createState() => _TutorialMenuScreenState();
}

class _TutorialMenuScreenState extends State<TutorialMenuScreen> {
  @override
  void initState() {
    super.initState();

    // Navegar automáticamente a la pantalla de videos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TutorialsScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Muestra solo un contenedor de fondo mientras navega automáticamente
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/f3.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.30),
        ),
      ),
    );
  }
}
