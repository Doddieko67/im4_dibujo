import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _username = '';
  bool _isLoading = false;
  bool _hoveringButton = false;

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(_email.trim(), _password);
      } else {
        await AuthService.signUpWithEmail(_email.trim(), _password);
        await _createUserProfile();
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final UserCredential? result = await AuthService.signInWithGoogle();
      
      if (result != null) {
        await _createUserProfile(isGoogleUser: true);
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserProfile({bool isGoogleUser = false}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      await userDoc.set({
        'email': user.email ?? _email.trim(),
        'username': isGoogleUser ? (user.displayName ?? 'Usuario') : _username.trim(),
        'level': 1,
        'experience': 0,
        'experienceTotal': 0,
        'profileImage': isGoogleUser 
            ? (user.photoURL ?? 'https://i.ibb.co/tqgf9gt/default-profile.png')
            : 'https://i.ibb.co/tqgf9gt/default-profile.png',
        'friends': [],
        'friendsCount': 0,
        'tutorialesCompletados': [],
      });

      await userDoc.collection('likedVideos').doc('firstVideo').set({
        'videoId': '',
        'title': '',
        'description': '',
        'thumbnail': '',
        'channelTitle': '',
        'publishedAt': '',
        'searchKeyword': '',
        'difficulty': '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF00BCD4); // Turquesa

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/origami_bg.jpg'), // Agrega esta imagen en tu carpeta assets
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Container(
            key: ValueKey(_isLogin),
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.85), Colors.pink[50]!.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: AnimatedOpacity(
                opacity: _isLoading ? 0.5 : 1,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.8, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      builder: (_, double scale, __) => Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Inicia sesión' : 'Regístrate',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PoetsenOne',
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (!_isLogin)
                      _buildAnimatedField(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Por favor ingresa un nombre de usuario' : null,
                          onSaved: (value) => _username = value ?? '',
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildAnimatedField(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 16),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value != null && value.contains('@') ? null : 'Correo inválido',
                        onSaved: (value) => _email = value ?? '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedField(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 16),
                        obscureText: true,
                        validator: (value) =>
                            value != null && value.length >= 6 ? null : 'Mínimo 6 caracteres',
                        onSaved: (value) => _password = value ?? '',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : MouseRegion(
                            onEnter: (_) => setState(() => _hoveringButton = true),
                            onExit: (_) => setState(() => _hoveringButton = false),
                            child: AnimatedScale(
                              scale: _hoveringButton ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: _hoveringButton ? 8 : 4,
                                  ),
                                  onPressed: _submit,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                    child: Text(
                                      _isLogin ? 'Iniciar sesión' : 'Registrarse',
                                      key: ValueKey(_isLogin),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'PoetsenOne',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    
                    // Divider con "O"
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'O',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontFamily: 'PoetsenOne',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Botón de Google
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: Image.asset(
                          'assets/icons/google_logo.png',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.account_circle,
                              size: 24,
                              color: Colors.grey.shade600,
                            );
                          },
                        ),
                        label: Text(
                          'Continuar con Google',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontFamily: 'PoetsenOne',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión',
                          key: ValueKey(_isLogin),
                          style: TextStyle(
                            color: primaryColor,
                            fontFamily: 'PoetsenOne',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedField({required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (_, double scale, __) => Transform.scale(scale: scale, child: child),
    );
  }
}
