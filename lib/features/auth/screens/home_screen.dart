//HomeScreen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'tutoriales_screen.dart';
import 'library_screen.dart';
import 'auth_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'setting_screen.dart';
import 'tutorial_menu_screen.dart';
import 'creative_screen.dart';
import '../../../screens/origami_history_screen.dart';





class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryColor = const Color.fromARGB(255, 45, 218, 200);
  int _currentIndex = 0;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "¡Bienvenido a OrigamiApp!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Explora arte y creatividad en papel",
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;

                if (isSmallScreen) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HomeButton(
                        icon: Icons.school_outlined,
                        label: 'Tutoriales',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TutorialMenuScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _HomeButton(
                        icon: Icons.book_outlined,
                        label: 'Biblioteca',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LibraryScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _HomeButton(
                        icon: Icons.lightbulb_outline,
                        label: 'Ponte creativo',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreativeScreen()),
                          );
                        },
                      ),
                    ],
                  );
                } else {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _HomeButton(
                        icon: Icons.school_outlined,
                        label: 'Tutoriales',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TutorialsScreen()),
                          );
                        },
                      ),
                      _HomeButton(
                        icon: Icons.book_outlined,
                        label: 'Biblioteca',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LibraryScreen()),
                          );
                        },
                      ),
                      _HomeButton(
                        icon: Icons.lightbulb_outline,
                        label: 'Ponte creativo',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreativeScreen()),
                          );
                        },
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final List<Widget> screens = [
      _buildHomeContent(),
      const SearchScreen(),
      const SettingsScreen(),
      ProfileScreen(userId: userId),
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 123, 123),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        title: _user != null
            ? _buildUserInfo(_user!)
            : const Text("Cargando...", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Historial de Origami',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrigamiHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color.fromARGB(255, 218, 218, 218),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildUserInfo(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5);
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("Cargando...", style: TextStyle(color: Colors.white));
        }

        var userData = snapshot.data!;
        String username = userData['username'] ?? 'Usuario';
        String profileImage = userData['profileImage'] ?? '';
        int level = userData['level'] ?? 1;

        ImageProvider imageProvider;
        if (profileImage.startsWith('assets/')) {
          imageProvider = AssetImage(profileImage);
        } else if (profileImage.startsWith('http')) {
          imageProvider = NetworkImage(profileImage);
        } else {
          imageProvider = const NetworkImage('https://i.ibb.co/tqgf9gt/default-profile.png');
        }

        return Row(
          children: [
            CircleAvatar(radius: 20, backgroundImage: imageProvider),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                Text('Nivel $level',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  String _getImagePath(String label) {
    switch (label) {
      case 'Tutoriales':
        return 'assets/images/tutorial.png';
      case 'Biblioteca':
        return 'assets/images/x.png';
      case 'Ponte creativo':
        return 'assets/images/f3.jpg'; 
      default:
        return 'assets/images/f5.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _getImagePath(label);

    final screenWidth = MediaQuery.of(context).size.width;
    final double size = screenWidth < 600 ? 300 : 340;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 60),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  shadows: [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
