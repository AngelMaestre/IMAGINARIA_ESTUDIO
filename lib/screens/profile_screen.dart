// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:share_plus/share_plus.dart';
import '../services/auth_linker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  bool _busy = false;

  fb.User? get _user => fb.FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final u = _user;
    _nameCtrl.text = u?.displayName ?? '';
    _photoCtrl.text = u?.photoURL ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final u = _user;
    if (u == null) return;
    setState(() => _busy = true);
    try {
      final name = _nameCtrl.text.trim();
      final photo = _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim();

      await u.updateDisplayName(name.isEmpty ? null : name);
      await u.updatePhotoURL(photo);
      await u.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await fb.FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pop(); // volver a Home
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkWeb() async {
    setState(() => _busy = true);
    try {
      final ok = await AuthLinker.openWebSso();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace SSO')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu perfil'),
        actions: [
          IconButton(
            tooltip: 'Compartir app',
            icon: const Icon(Icons.share),
            onPressed: () => Share.share('Descubre Imaginaria ✨'),
          )
        ],
      ),
      body: u == null
          ? const Center(child: Text('No has iniciado sesión'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AbsorbPointer(
                absorbing: _busy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera con avatar y email
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: (u.photoURL != null && u.photoURL!.isNotEmpty)
                              ? NetworkImage(u.photoURL!)
                              : null,
                          child: (u.photoURL == null || u.photoURL!.isEmpty)
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.email ?? 'Sin email',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                u.uid,
                                style: const TextStyle(fontSize: 12, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Nombre para mostrar
                    const Text('Nombre para mostrar'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Tu nombre',
                        filled: true,
                        fillColor: const Color(0xFF1F2937),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // URL de avatar (simple, sin upload por ahora)
                    const Text('URL de avatar (opcional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _photoCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        filled: true,
                        fillColor: const Color(0xFF1F2937),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onSubmitted: (_) => _saveProfile(),
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: _busy ? const Text('Guardando...') : const Text('Guardar cambios'),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Enlace con web (SSO)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link),
                      title: const Text('Conectar sesión con la web'),
                      subtitle: const Text('Enlaza tu sesión con el sitio para no volver a registrarte'),
                      onTap: _linkWeb,
                      trailing: const Icon(Icons.chevron_right),
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Cerrar sesión
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: _busy ? const Text('Cerrando...') : const Text('Cerrar sesión'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
