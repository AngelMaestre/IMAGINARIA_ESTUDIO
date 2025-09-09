// lib/services/cache.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppCache {
  static const _prefix = 'cache:';
  static const defaultTtl = Duration(minutes: 30);

  /// Lee desde caché y deserializa opcionalmente con [fromJson] o [fromListJson].
  /// - Si guardaste un objeto (Map), usa [fromJson].
  /// - Si guardaste una lista (List), usa [fromListJson].
  static Future<T?> get<T>(
    String key, {
    Duration ttl = defaultTtl,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(List<dynamic>)? fromListJson,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('$_prefix$key');
    if (raw == null) return null;

    final obj = jsonDecode(raw) as Map<String, dynamic>;
    final tsIso = obj['ts'] as String?;
    final ts = tsIso != null ? DateTime.tryParse(tsIso) : null;
    if (ts == null || DateTime.now().difference(ts) > ttl) {
      return null; // caducado
    }

    final data = obj['data'];

    if (data is List && fromListJson != null) {
      // Aseguramos tipo List<dynamic>
      final list = List<dynamic>.from(data);
      return fromListJson(list);
    }

    if (data is Map && fromJson != null) {
      // 👉 Cast seguro a Map<String, dynamic>
      final map = Map<String, dynamic>.from(data as Map);
      return fromJson(map);
    }

    // Fallback: intentamos castear directamente
    return data as T?;
  }

  /// Guarda cualquier estructura JSON-encodable (Map/List/num/bool/String/null).
  static Future<void> set(String key, Object? data) async {
    final sp = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'ts': DateTime.now().toIso8601String(),
      'data': data,
    };
    await sp.setString('$_prefix$key', jsonEncode(payload));
  }

  static Future<void> invalidate(String key) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$_prefix$key');
  }
}
