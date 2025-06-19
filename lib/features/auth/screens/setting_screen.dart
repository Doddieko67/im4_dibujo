//Ajustes
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estado para controlar el tema
  bool isDarkMode = false;

  // Función para cambiar el tema entre claro y oscuro
  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF1F6F9),
      
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsTile(
            icon: Icons.palette,
            title: "Tema",
            subtitle: isDarkMode ? "Oscuro" : "Claro",
            onTap: _toggleTheme, // Cambiar el tema al tocar el botón
          ),
          _SettingsTile(
            icon: Icons.notifications,
            title: "Notificaciones",
            subtitle: "Activadas",
            onTap: () async {
              // Mostrar un diálogo para activar/desactivar notificaciones
              final result = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Notificaciones'),
                      content: const Text(
                        '¿Quieres activar las notificaciones?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Desactivar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Activar'),
                        ),
                      ],
                    ),
              );
              if (result != null) {
                // Aquí agregar lógica para manejar el estado de las notificaciones
                print(
                  result
                      ? "Notificaciones Activadas"
                      : "Notificaciones Desactivadas",
                );
              }
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: "Acerca de",
            subtitle: "Versión 1.0.0",
            onTap: () {
              // Mostrar información de la versión
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Acerca de la Aplicación'),
                      content: const Text(
                        'Versión 1.0.0\nDesarrollada por Tu Nombre',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00BCD4)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
