import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diagnosis_result.dart';

class HistoryService {
  static const String _key = 'padiscan_history_items';
  static final ValueNotifier<int> historyNotifier = ValueNotifier<int>(0);

  static Future<List<DiagnosisResult>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_key) ?? [];
      return rawList
          .map((item) => DiagnosisResult.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('HistoryService getHistory error: $e');
      return [];
    }
  }

  static Future<void> saveResult(DiagnosisResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      
      // Batasi maksimal 100 riwayat tersimpan
      history.removeWhere((item) => item.id == result.id);
      history.insert(0, result);
      if (history.length > 100) {
        history.removeLast();
      }

      final rawList = history.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_key, rawList);
      historyNotifier.value++;
    } catch (e) {
      debugPrint('HistoryService saveResult error: $e');
    }
  }

  static Future<void> deleteResult(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      history.removeWhere((item) => item.id == id);
      final rawList = history.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_key, rawList);
      historyNotifier.value++;
    } catch (e) {
      debugPrint('HistoryService deleteResult error: $e');
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    historyNotifier.value++;
  }

  /// Salin berkas gambar sementara ke direktori permanen aplikasi
  static Future<String> persistImage(String tempPath, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/scans');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final targetPath = '${imagesDir.path}/$fileName';
      await File(tempPath).copy(targetPath);
      return targetPath;
    } catch (e) {
      debugPrint('HistoryService persistImage error: $e');
      return tempPath;
    }
  }
}
