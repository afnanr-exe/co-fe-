// lib/services/word_service.dart

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word.dart';

class WordService {
  static const _keyCustomWords =
      'custom_words';

  static const _keyImportCount =
      'daily_import_count';

  static const _keyImportDate =
      'daily_import_date';

  static List<Word>? _cachedWords;

  static Future<List<Word>> getWords() async {
    if (_cachedWords != null) {
      return _cachedWords!;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final stored =
        prefs.getString(_keyCustomWords);

    if (stored != null) {
      final decoded = jsonDecode(stored) as List;

      _cachedWords =
          decoded.map((w) => _fromMap(w)).toList();

      return _cachedWords!;
    }

    final raw =
        await rootBundle.loadString(
      'assets/words.json',
    );

    final list = jsonDecode(raw) as List;

    _cachedWords =
        list.map((w) => _fromMap(w)).toList();

    return _cachedWords!;
  }

  static Future<void> saveCustomWords(
    List<Map<String, dynamic>> words,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _keyCustomWords,
      jsonEncode(words),
    );

    _cachedWords = null;
  }

  static Future<void> resetWords() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_keyCustomWords);

    _cachedWords = null;
  }

  static Future<bool> canImportWords() async {
    final prefs =
        await SharedPreferences.getInstance();

    final today =
        DateTime.now().toIso8601String().substring(0, 10);

    final savedDate =
        prefs.getString(_keyImportDate);

    if (savedDate != today) {
      await prefs.setString(
        _keyImportDate,
        today,
      );

      await prefs.setInt(
        _keyImportCount,
        0,
      );

      return true;
    }

    final count =
        prefs.getInt(_keyImportCount) ?? 0;

    return count < 3;
  }

  static Future<void> incrementImportCount() async {
    final prefs =
        await SharedPreferences.getInstance();

    final count =
        prefs.getInt(_keyImportCount) ?? 0;

    await prefs.setInt(
      _keyImportCount,
      count + 1,
    );
  }

  static Future<int> remainingImports() async {
    final prefs =
        await SharedPreferences.getInstance();

    final today =
        DateTime.now().toIso8601String().substring(0, 10);

    final savedDate =
        prefs.getString(_keyImportDate);

    if (savedDate != today) {
      return 3;
    }

    final count =
        prefs.getInt(_keyImportCount) ?? 0;

    return 3 - count;
  }

  static Future<Word> getRandomWord() async {
    final words = await getWords();

    final random = Random();

    return words[random.nextInt(words.length)];
  }

  static Future<Word> getWordOfTheDay() async {
    final words = await getWords();

    final now = DateTime.now();

    final seed =
        now.year * 1000 +
        now.month * 100 +
        now.day;

    final index = seed % words.length;

    return words[index];
  }

  static Future<List<Word>>
      getWordsByDifficulty(int tier) async {
    final words = await getWords();

    return words
        .where(
          (w) => w.difficultyTier == tier,
        )
        .toList();
  }

  static Word _fromMap(
    Map<String, dynamic> map,
  ) {
    final distractors = _generateDistractors(
      map['definition'].toString(),
    );

    return Word(
      term: map['term'] ?? '',
      definition: map['definition'] ?? '',
      exampleSentence:
          map['exampleSentence'] ?? '',
      difficultyTier:
          map['difficultyTier'] ?? 1,
      language: map['language'] ?? 'en',
      etymology:
          map['etymology'] ?? 'Origin unknown',
      partOfSpeech:
          map['partOfSpeech'] ?? 'noun',
      pronunciation:
          map['pronunciation'] ?? '',
      distractors: distractors,
    );
  }

  static List<String> _generateDistractors(
    String correctDef,
  ) {
    final pool = [
      'to move quickly and without direction',
      'relating to the study of ancient texts',
      'a feeling of deep satisfaction or contentment',
      'marked by excessive pride or self-confidence',
      'the quality of being unclear or difficult to understand',
      'to weaken or reduce in strength or effectiveness',
      'characterized by sudden and unpredictable change',
      'a state of perfect happiness or peace',
      'having a sharp, pungent taste or smell',
      'showing a lack of experience or judgment',
      'the tendency to expect the best outcome',
      'relating to or involving physical sensation',
      'an overwhelming feeling of reverence or admiration',
      'marked by careful attention to detail',
      'the quality of being open and honest',
      'a feeling of listlessness and dissatisfaction',
      'to speak or write at excessive length',
      'showing or characterized by deep insight',
      'relating to the essential nature of something',
      'a pleasant feeling of excitement and anticipation',
      'a deep sense of emotional longing',
      'to gradually disappear or diminish',
      'marked by elegance and sophistication',
      'a refusal to change one’s opinion or course',
      'the act of avoiding responsibility or blame',
      'filled with energy and enthusiasm',
      'a calm and peaceful mental state',
      'difficult to understand or interpret',
      'to express strong disapproval publicly',
      'having a dreamlike or surreal quality',
      'to recover quickly from hardship or adversity',
      'an intense feeling of joy or triumph',
      'showing restraint and self-discipline',
      'a tendency toward gloomy thinking',
      'to speak in a vague or evasive manner',
      'marked by confidence and composure',
      'a sudden burst of inspiration or creativity',
      'to wander aimlessly without purpose',
      'having a rough or harsh texture',
      'the state of being highly respected',
      'a quiet feeling of sadness or regret',
      'to deliberately make something confusing',
      'characterized by warmth and friendliness',
      'the ability to judge situations wisely',
      'showing boldness in the face of danger',
      'a subtle feeling of anxiety or doubt',
      'filled with vibrant color and life',
      'to strongly desire wealth or power',
      'marked by emotional sensitivity',
      'having an old-fashioned charm',
      'a situation filled with confusion or disorder',
      'to become larger or more intense over time',
      'the quality of being morally upright',
      'to criticize in a mocking or cruel way',
      'having a smooth and flowing quality',
      'a feeling of awe mixed with fear',
      'to act in a dishonest or misleading manner',
      'marked by excessive enthusiasm or devotion',
      'a temporary period of decline or weakness',
      'to praise someone excessively for advantage',
      'filled with mystery or uncertainty',
      'a state of emotional exhaustion',
      'showing a cheerful and lively attitude',
      'to carefully examine or analyze',
      'marked by stubborn determination',
      'a strong feeling of resentment',
      'to speak with passion and intensity',
      'having a faint or delicate appearance',
      'a feeling of isolation from others',
      'to improve or make something better',
      'marked by unpredictable behavior',
      'a deep understanding gained through experience',
      'to become less severe over time',
      'showing kindness and generosity',
      'a sudden realization or moment of clarity',
      'filled with tension or suspense',
      'to act with excessive pride or arrogance',
      'having a bright and radiant quality',
      'a tendency to avoid social interaction',
      'to remain calm under pressure',
    ];

    pool.shuffle(Random());

    return pool
        .where((d) => d != correctDef)
        .take(3)
        .toList();
  }
}