// lib/services/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/auth_screen.dart';

/// Esta clase decide qué mostrar según si el usuario está logueado o no.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.active) {
          return const Material(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return const AuthScreen(); // no logueado → login/registro
        return const HomeScreen(); // logueado → home normal
      },
    );
  }
}
