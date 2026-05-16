// lib/services/stats_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static const _keyCorrect = 'stat_correct';
  static const _keyAssisted = 'stat_assisted';
  static const _keyWrong = 'stat_wrong';
  static const _keyStreak = 'stat_streak';
  static const _keyBestStreak = 'stat_best_streak';
  static const _keyLastPlayed = 'stat_last_played';
  static const _keyMissedWords = 'stat_missed_words';
  static const _keyWeeklyActivity = 'stat_weekly_activity';
  // separate key so resets can't re-unlock today's puzzle
  static const _keyPuzzlePlayedDate = 'stat_puzzle_played_date';

  // =========================
  // SAVE RESULT
  // =========================
  static Future<void> saveResult({
    required String wordTerm,
    required bool correct,
    required bool usedHint,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastPlayed = prefs.getString(_keyLastPlayed) ?? '';

    String outcome;

    if (correct && usedHint) {
      outcome = 'assisted';
      final current = prefs.getInt(_keyAssisted) ?? 0;
      await prefs.setInt(_keyAssisted, current + 1);
    } else if (correct) {
      outcome = 'correct';
      final current = prefs.getInt(_keyCorrect) ?? 0;
      await prefs.setInt(_keyCorrect, current + 1);
    } else {
      outcome = 'wrong';
      final current = prefs.getInt(_keyWrong) ?? 0;
      await prefs.setInt(_keyWrong, current + 1);

      final missed = prefs.getStringList(_keyMissedWords) ?? [];

      if (!missed.contains(wordTerm)) {
        missed.add(wordTerm);
        await prefs.setStringList(_keyMissedWords, missed);
      }
    }

    // =========================
    // WEEKLY ACTIVITY (FIXED SAFE PARSING)
    // =========================
    final activityRaw = prefs.getStringList(_keyWeeklyActivity) ?? [];

    final Map<String, String> activity = {};
    for (final e in activityRaw) {
      final parts = e.split(':');
      if (parts.length == 2) {
        activity[parts[0]] = parts[1];
      }
    }

    activity[today] = outcome;

    // trim entries older than 30 days
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String()
        .substring(0, 10);
    activity.removeWhere((key, _) => key.compareTo(cutoff) < 0);

    await prefs.setStringList(
      _keyWeeklyActivity,
      activity.entries.map((e) => '${e.key}:${e.value}').toList(),
    );

    // mark puzzle as played today (not cleared by reset)
    await prefs.setString(_keyPuzzlePlayedDate, today);

    // =========================
    // STREAK LOGIC (UNCHANGED BUT SAFE)
    // =========================
    if (lastPlayed != today) {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);

      int streak = prefs.getInt(_keyStreak) ?? 0;

      if (lastPlayed == yesterday) {
        streak += 1;
      } else {
        streak = 1;
      }

      await prefs.setInt(_keyStreak, streak);

      final best = prefs.getInt(_keyBestStreak) ?? 0;

      if (streak > best) {
        await prefs.setInt(_keyBestStreak, streak);
      }

      await prefs.setString(_keyLastPlayed, today);
    }
  }

  // =========================
  // GET STATS
  // =========================
  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();

    final activityRaw = prefs.getStringList(_keyWeeklyActivity) ?? [];

    final Map<String, String> activity = {};
    for (final e in activityRaw) {
      final parts = e.split(':');
      if (parts.length == 2) {
        activity[parts[0]] = parts[1];
      }
    }

    return {
      'correct': prefs.getInt(_keyCorrect) ?? 0,
      'assisted': prefs.getInt(_keyAssisted) ?? 0,
      'wrong': prefs.getInt(_keyWrong) ?? 0,
      'streak': prefs.getInt(_keyStreak) ?? 0,
      'bestStreak': prefs.getInt(_keyBestStreak) ?? 0,
      'missedWords': prefs.getStringList(_keyMissedWords) ?? [],
      'weeklyActivity': activity,
    };
  }

  // =========================
  // MISSed WORDS
  // =========================
  static Future<bool> isPuzzleCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return (prefs.getString(_keyPuzzlePlayedDate) ?? '') == today;
  }

  static Future<void> clearMissedWords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyMissedWords, []);
  }

  // =========================
  // FULL RESET (FIXED — THIS WAS YOUR MAIN ISSUE)
  // =========================
  static Future<void> resetAllStats() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyCorrect);
    await prefs.remove(_keyAssisted);
    await prefs.remove(_keyWrong);

    await prefs.remove(_keyStreak);
    await prefs.remove(_keyBestStreak);
    await prefs.remove(_keyLastPlayed);

    await prefs.remove(_keyMissedWords);
    await prefs.remove(_keyWeeklyActivity);

    // IMPORTANT: ensures no ghost state survives
    await prefs.setInt(_keyCorrect, 0);
    await prefs.setInt(_keyAssisted, 0);
    await prefs.setInt(_keyWrong, 0);
    await prefs.setInt(_keyStreak, 0);
    await prefs.setInt(_keyBestStreak, 0);
  }
}