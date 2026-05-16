import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word.dart';
import 'dictionary_service.dart';
import 'quiz_service.dart';
import 'stats_service.dart';
import 'word_service.dart';

class SettingsService {
  static const _keyAppStartDate = 'app_start_date';
  static const _keyMwApiKey = 'mw_api_key';

  static const _keyCustomChangesToday = 'custom_changes_today';
  static const _keyCustomChangeDate = 'custom_change_date';

  static const _maxChangesPerDay = 3;

  // =========================
  // MW API KEY
  // =========================

  static Future<String?> getMWApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyMwApiKey) ?? '';
    return key.isNotEmpty ? key : null;
  }

  static Future<void> setMWApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMwApiKey, key.trim());
  }

  // =========================
  // APP DATE SYSTEM
  // =========================

  static Future<void> initializeAppDate() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_keyAppStartDate)) {
      await prefs.setString(
        _keyAppStartDate,
        DateTime.now().toIso8601String(),
      );
    }
  }

  static Future<DateTime> getAppStartDate() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_keyAppStartDate);

    if (raw == null) {
      final now = DateTime.now();

      await prefs.setString(
        _keyAppStartDate,
        now.toIso8601String(),
      );

      return now;
    }

    return DateTime.parse(raw);
  }

  static Future<int> getCurrentDayIndex() async {
    final start = await getAppStartDate();

    return DateTime.now()
        .difference(start)
        .inDays;
  }

  // =========================
  // RESET
  // =========================

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // clears stats + quiz data
    await QuizService.clearAllQuizData();
    await StatsService.resetAllStats();

    // reset app progression
    await prefs.setString(
      _keyAppStartDate,
      DateTime.now().toIso8601String(),
    );

    // reset import limits
    await prefs.setInt(
      _keyCustomChangesToday,
      0,
    );

    await prefs.setString(
      _keyCustomChangeDate,
      DateTime.now()
          .toIso8601String()
          .substring(0, 10),
    );
  }

  static Future<void> fullReset() async {
    await resetProgress();
  }

  // =========================
  // WORD IMPORT LIMIT SYSTEM
  // =========================

  static Future<bool> canChangeWordList() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now()
        .toIso8601String()
        .substring(0, 10);

    final savedDate =
        prefs.getString(_keyCustomChangeDate);

    if (savedDate != today) {
      await prefs.setString(
        _keyCustomChangeDate,
        today,
      );

      await prefs.setInt(
        _keyCustomChangesToday,
        0,
      );

      return true;
    }

    final changes =
        prefs.getInt(_keyCustomChangesToday) ?? 0;

    return changes < _maxChangesPerDay;
  }

  static Future<int> remainingChangesToday() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now()
        .toIso8601String()
        .substring(0, 10);

    final savedDate =
        prefs.getString(_keyCustomChangeDate);

    if (savedDate != today) {
      return _maxChangesPerDay;
    }

    final used =
        prefs.getInt(_keyCustomChangesToday) ?? 0;

    return max(
      0,
      _maxChangesPerDay - used,
    );
  }

  static Future<void> _incrementChanges() async {
    final prefs = await SharedPreferences.getInstance();

    final current =
        prefs.getInt(_keyCustomChangesToday) ?? 0;

    await prefs.setInt(
      _keyCustomChangesToday,
      current + 1,
    );
  }

  // =========================
  // WORD PARSING
  // =========================

  static List<String> parseWords(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll(',', ' ')
        .replaceAll('\n', ' ')
        .trim();

    return cleaned
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  // =========================
  // IMPORT WORDS
  // =========================

  static Future<Map<String, dynamic>> importCustomWords(
    String input, {
    void Function(int done, int total)? onProgress,
  }) async {
    final allowed = await canChangeWordList();
    if (!allowed) {
      return {
        'success': false,
        'message': 'Daily limit reached (3 changes/day).',
      };
    }

    final parsed = parseWords(input);
    if (parsed.isEmpty) {
      return {'success': false, 'message': 'No valid words found.'};
    }
    if (parsed.length > 365) {
      return {'success': false, 'message': 'Max 365 words allowed.'};
    }

    final mwKey = await getMWApiKey();

    // Fetch definitions for all words in parallel batches
    final lookups = await DictionaryService.lookupBatch(
      parsed,
      mwKey: mwKey,
      onProgress: onProgress,
    );

    final existing = await WordService.getWords();
    final updated = List<Word>.from(existing);
    final rand = Random();

    for (int i = 0; i < parsed.length; i++) {
      final term = parsed[i];
      final data = lookups[i];

      final newWord = Word(
        term: term,
        definition: data?['definition']?.isNotEmpty == true
            ? data!['definition']!
            : 'No definition available.',
        exampleSentence: data?['exampleSentence']?.isNotEmpty == true
            ? data!['exampleSentence']!
            : 'No example sentence available.',
        difficultyTier: 2,
        language: 'en',
        etymology: data?['etymology']?.isNotEmpty == true
            ? data!['etymology']!
            : 'No etymology available.',
        partOfSpeech: data?['partOfSpeech'] ?? 'unknown',
        pronunciation: data?['pronunciation']?.isNotEmpty == true
            ? data!['pronunciation']!
            : term,
        distractors: const [],
      );

      if (updated.isNotEmpty) {
        updated[rand.nextInt(updated.length)] = newWord;
      } else {
        updated.add(newWord);
      }
    }

    await WordService.saveCustomWords(
      updated.map((w) => {
        'term': w.term,
        'definition': w.definition,
        'exampleSentence': w.exampleSentence,
        'difficultyTier': w.difficultyTier,
        'language': w.language,
        'etymology': w.etymology,
        'partOfSpeech': w.partOfSpeech,
        'pronunciation': w.pronunciation,
      }).toList(),
    );

    await _incrementChanges();

    final enriched = lookups.where((r) => r != null).length;
    return {
      'success': true,
      'imported': parsed.length,
      'enriched': enriched,
      'remaining': await remainingChangesToday(),
    };
  }

  // =========================
  // EXPORT
  // =========================

  static Future<String> exportWordList() async {
    final words =
        await WordService.getWords();

    return words
        .map((w) => w.term)
        .join(', ');
  }
}