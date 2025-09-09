import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import 'package:shared_preferences/shared_preferences.dart';
class FavoritesService {
  static const _key = 'favorites_v1';

  Future<List<PostItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(PostItem.fromJson).toList();
  }

  Future<void> save(List<PostItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> toggle(PostItem item) async {
    final list = await load();
    final exists = list.any((e) => e.id == item.id && e.sourceKey == item.sourceKey);
    if (exists) {
      list.removeWhere((e) => e.id == item.id && e.sourceKey == item.sourceKey);
    } else {
      list.insert(0, item);
    }
    await save(list);
  }

  Future<bool> isFavorite(PostItem item) async {
    final list = await load();
    return list.any((e) => e.id == item.id && e.sourceKey == item.sourceKey);
  }
}
