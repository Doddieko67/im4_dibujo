//animacion de inicio
import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late Animation<int> _textAnimation;
  late AnimationController _logoAnimationController;

  final String fullText = "Mundo Origami";
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();

    _textAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: fullText.length * 150),
    );

    _textAnimation = StepTween(begin: 0, end: fullText.length).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeIn,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showLogo = true);
          _logoAnimationController.forward();

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
          });
        }
      });

    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _textAnimationController.forward();
  }

  @override
  void dispose() {
    _textAnimationController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width > 600;

    double logoSize = screenSize.width * 0.5;
    if (logoSize < 150) logoSize = 150;
    if (logoSize > 300) logoSize = 300;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00BCD4), Color(0xFFB2EBF2)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo con animación
                AnimatedBuilder(
                  animation: _logoAnimationController,
                  builder: (_, child) {
                    return Opacity(
                      opacity: _logoAnimationController.value,
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * _logoAnimationController.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/icons/logo.png',
                    height: logoSize,
                  ),
                ),
                const SizedBox(height: 30),

                // Texto animado con fuente personalizada
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    String visibleText =
                        fullText.substring(0, _textAnimation.value);
                    return Text(
                      visibleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWide ? 48 : 36,
                        color: const Color(0xFF2E2E2E),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Origame',
                        letterSpacing: 1.5,
                        shadows: const [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                if (!_showLogo)
                  SizedBox(
                    height: 3,
                    width: 120,
                    child: LinearProgressIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.transparent,
                      minHeight: 3,
                      value: _textAnimationController.value,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
