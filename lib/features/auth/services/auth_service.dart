import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado por el usuario');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Error al obtener tokens de autenticación');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('Ya existe una cuenta con este email usando otro método de acceso');
        case 'invalid-credential':
          throw Exception('Las credenciales de Google no son válidas');
        case 'operation-not-allowed':
          throw Exception('El acceso con Google no está habilitado');
        case 'user-disabled':
          throw Exception('Esta cuenta ha sido deshabilitada');
        default:
          throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      if (e.toString().contains('network_error')) {
        throw Exception('Error de conexión. Verifica tu internet');
      } else if (e.toString().contains('sign_in_canceled')) {
        throw Exception('Inicio de sesión cancelado');
      } else {
        throw Exception('Error inesperado: ${e.toString()}');
      }
    }
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
