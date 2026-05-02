// lib/data/repositories/share_codes_repository.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/share_code.dart';

class ShareCodesRepository {
  static const _key = 'generated_share_codes';

  Future<List<ShareCode>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => ShareCode.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<ShareCode> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      codes.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }
}
