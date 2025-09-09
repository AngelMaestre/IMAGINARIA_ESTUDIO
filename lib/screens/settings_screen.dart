// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'auth_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  /// Callback opcional para notificar cambios de tema al nivel superior (main.dart)
  final ValueChanged<bool>? onThemeChanged;

  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;        // placeholder
  bool _notifEnabled = true;     // placeholder

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = sp.getBool('pref_dark_mode') ?? false;
      _notifEnabled = sp.getBool('pref_notif_enabled') ?? true;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final user = fb.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // ===== Cuenta / Perfil =====
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (user == null)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Iniciar sesión'),
              subtitle: const Text('Accede para gestionar tu perfil'),
              onTap: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                if (ok == true && mounted) setState(() {});
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil de usuario'),
              subtitle: Text(user.email ?? user.uid),
              trailing: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: const Text('Editar'),
              ),
            ),

          const Divider(height: 24),

          // ===== Preferencias (guardan en SharedPreferences) =====
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Preferencias', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            value: _darkMode,
            onChanged: (v) async {
              setState(() => _darkMode = v);
              await _savePref('pref_dark_mode', v);

              // Notificamos hacia arriba si main.dart quiere reaccionar en caliente
              widget.onThemeChanged?.call(v);

              if (!mounted) return;
              // Si no tienes theming dinámico aún, avisamos que se aplicará al reiniciar
              if (widget.onThemeChanged == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El tema se aplicará en el próximo arranque'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          SwitchListTile(
            title: const Text('Notificaciones'),
            value: _notifEnabled,
            onChanged: (v) async {
              setState(() => _notifEnabled = v);
              await _savePref('pref_notif_enabled', v);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ajuste guardado (gestión por el sistema)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
