// lib/services/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';

/// Devuelve true si el usuario acaba logueado; de lo contrario, false.
Future<bool> ensureSignedIn(BuildContext context) async {
  if (FirebaseAuth.instance.currentUser != null) return true;

  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const AuthScreen()),
  );

  // Si AuthScreen hace pop(true) o si tras volver hay user, seguimos
  return ok == true || FirebaseAuth.instance.currentUser != null;
}
