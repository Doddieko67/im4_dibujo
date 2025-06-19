//perfil de usuario
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      setState(() {
        userData = doc.data();
      });
    }
  }

  void _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF00BCD4);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo con opacidad baja
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/images/f2.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenido principal con degradado sutil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF008BA3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Scaffold transparente encima
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Perfil de Usuario'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                  onPressed: _logout,
                ),
              ],
            ),
            body: userData == null
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 600 : double.infinity,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: primaryColor,
                                child: Text(
                                  (userData!['username'] ?? 'U')
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.white.withOpacity(0.9),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userData!['username'] ??
                                          'Nombre no disponible',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.email,
                                            color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          userData!['email'] ??
                                              'Email no disponible',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _InfoBadge(
                                          icon: Icons.star,
                                          label: 'Nivel',
                                          value: userData!['level']
                                                  ?.toString() ??
                                              '1',
                                          color: Colors.amber.shade700,
                                        ),
                                        _InfoBadge(
                                          icon: Icons.school,
                                          label: 'Experiencia',
                                          value: userData!['experience']
                                                  ?.toString() ??
                                              '0',
                                          color: Colors.lightBlue,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Origamis guardados:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: (userData!['likedVideos'] as List).isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No tienes origamis guardados aún.',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white70),
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          (userData!['likedVideos'] as List)
                                              .map<Widget>(
                                                (video) => Chip(
                                                  label: Text(video),
                                                  avatar: const Icon(
                                                      Icons.video_library,
                                                      size: 20),
                                                  backgroundColor:
                                                      primaryColor
                                                          .withOpacity(0.2),
                                                ),
                                              )
                                              .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        )
      ],
    );
  }
}
