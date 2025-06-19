import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF008BA3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Usuarios"),
            centerTitle: true,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWideScreen ? 600 : double.infinity),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=${index + 1}',
                        ),
                      ),
                      title: Text(
                        "Usuario ${index + 1}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: const Text("Perfil básico"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
