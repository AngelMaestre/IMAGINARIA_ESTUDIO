// lib/screens/upload_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<PlatformFile> _files = [];
  bool _busy = false;
  String? _status;

  Future<void> _pickFiles() async {
    setState(() => _status = null);
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;
      setState(() => _files = res.files);
    } catch (e) {
      setState(() => _status = 'Error al seleccionar archivos: $e');
    }
  }

  Future<void> _shareFiles() async {
    if (_files.isEmpty) return;
    final paths = _files.map((f) => f.path).whereType<String>().toList();
    await Share.shareXFiles(paths.map((p) => XFile(p)).toList());
  }

  Future<void> _uploadFiles() async {
    if (_files.isEmpty) return;

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      // TODO: Cambia por tu endpoint real
      final uri = Uri.parse('https://YOUR_UPLOAD_ENDPOINT_HERE');
      final req = http.MultipartRequest('POST', uri);

      for (final f in _files) {
        final path = f.path;
        if (path == null) continue;
        final file = File(path);
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        req.files.add(http.MultipartFile(
          'files', // nombre del campo esperado por tu servidor
          stream,
          length,
          filename: f.name,
        ));
      }

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() => _status = 'Subida correcta (${resp.statusCode})');
      } else {
        setState(() => _status = 'Fallo al subir (${resp.statusCode}): $body');
      }
    } catch (e) {
      setState(() => _status = 'Error de red: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = _files.isNotEmpty && !_busy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir archivos'),
        actions: [
          IconButton(
            tooltip: 'Seleccionar',
            onPressed: _busy ? null : _pickFiles,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_status != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black26,
              child: Text(_status!, style: const TextStyle(color: Colors.white)),
            ),
          Expanded(
            child: _files.isEmpty
                ? const Center(
                    child: Text('No hay archivos seleccionados'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, i) {
                      final f = _files[i];
                      final sizeKb = f.size / 1024;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white12),
                        ),
                        title: Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${sizeKb.toStringAsFixed(1)} KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _busy
                              ? null
                              : () => setState(() => _files.removeAt(i)),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: _files.length,
                  ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _files.isEmpty || _busy ? null : _shareFiles,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Compartir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canUpload ? _uploadFiles : null,
                    icon: _busy
                        ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: const Text('Subir'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _pickFiles,
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),
    );
  }
}
