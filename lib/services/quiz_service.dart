import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_result.dart';
import '../models/monthly_score.dart';
import '../models/yearly_score.dart';


class QuizService {
  static const _keyLastQuizDate = 'quiz_last_date';
  static const _keyQuizResults = 'quiz_results';
  static const _keyMonthlyScores = 'quiz_monthly_scores';
  static const _keyYearlyScores = 'quiz_yearly_scores';
  static const _keyPendingResult = 'quiz_pending_result';
  static const _keyLastResult = 'quiz_last_result';

  // =========================
  // HABIT SYSTEM
  // =========================

  static const _keyHabitScore = 'quiz_habit_score';
  static const _keyHabitLastUpdate = 'quiz_habit_last_update';
  static const _keyMissedBaseline = 'quiz_missed_baseline';
  static const _quizUnlockThreshold = 3;

  // =========================
  // QUIZ AVAILABILITY
  // =========================

  static Future<bool> isQuizReady() async {
    final prefs = await SharedPreferences.getInstance();
    final missed = prefs.getStringList('stat_missed_words') ?? [];
    final baseline = prefs.getInt(_keyMissedBaseline) ?? 0;

    return missed.length >= baseline + _quizUnlockThreshold;
  }

  static Future<int> mistakesUntilQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final missed = prefs.getStringList('stat_missed_words') ?? [];
    final baseline = prefs.getInt(_keyMissedBaseline) ?? 0;
    final needed = (baseline + _quizUnlockThreshold) - missed.length;
    return needed > 0 ? needed : 0;
  }

  static Future<bool> isInCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastQuiz = prefs.getString(_keyLastQuizDate);

    if (lastQuiz == null) return false;

    final last = DateTime.tryParse(lastQuiz);
    if (last == null) return false;

    return DateTime.now().difference(last).inHours < 24;
  }

  static Future<Duration?> cooldownRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final lastQuiz = prefs.getString(_keyLastQuizDate);

    if (lastQuiz == null) return null;

    final last = DateTime.tryParse(lastQuiz);
    if (last == null) return null;

    final expiry = last.add(const Duration(hours: 24));

    if (expiry.isBefore(DateTime.now())) return null;

    return expiry.difference(DateTime.now());
  }

  // =========================
  // PENDING RESULT
  // =========================

  static Future<QuizResult?> getPendingResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingResult);

    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final result = QuizResult.fromMap(map);

    if (result.expiresAt.isBefore(DateTime.now())) {
      await _clearPendingResult();
      return null;
    }

    return result;
  }

  static Future<Duration?> timeUntilExpiry() async {
    final result = await getPendingResult();
    if (result == null) return null;
    return result.expiresAt.difference(DateTime.now());
  }

  static Future<void> _clearPendingResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingResult);
  }

  // =========================
  // SCORING
  // =========================

  static double _calculatePerformanceScore({
    required int correct,
    required int total,
    required double avgDifficulty,
  }) {
    if (total == 0) return 0;

    final accuracy = correct / total;
    final difficultyWeight = 0.7 + (avgDifficulty / 5 * 0.3);

    return (accuracy * difficultyWeight * 100).clamp(0, 100);
  }

  static Future<double> _calculateHabitScore({
    required double performanceScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    double current =
        prefs.getDouble(_keyHabitScore) ?? 0;

    final lastRaw =
        prefs.getString(_keyHabitLastUpdate);

    final now = DateTime.now();

    // =========================
    // DECAY — 5 pts per missed day, floor 0
    // First missed day: -5, second: -10, etc.
    // =========================

    if (lastRaw != null) {
      final last = DateTime.tryParse(lastRaw);

      if (last != null) {
        final daysAway = now.difference(last).inDays;

        if (daysAway == 1) {
          current -= 5;
        } else if (daysAway == 2) {
          current -= 12;
        } else if (daysAway >= 3) {
          // accelerates after 2 consecutive misses
          current -= 12 + (daysAway - 2) * 8;
        }
      }
    }

    current = current.clamp(0, 100);

    // =========================
    // QUIZ IMPACT
    // Showing up = habit. Right answer = bonus.
    // Wrong answer still earns pts — you came back.
    // =========================

    if (performanceScore >= 90) {
      current += 18;
    } else if (performanceScore >= 60) {
      current += 12;
    } else {
      current += 5;
    }

    current = current.clamp(0, 100);

    await prefs.setDouble(_keyHabitScore, current);

    await prefs.setString(
      _keyHabitLastUpdate,
      now.toIso8601String(),
    );

    return current;
  }

  static double _calculateFinalScore(double performance, double habit) {
    return (performance * (0.7 + (habit / 100 * 0.3))).clamp(0, 100);
  }

  // =========================
  // SAVE QUIZ RESULT
  // =========================

  static Future<QuizResult> saveQuizResult({
    required List<String> masteredWords,
    required List<String> missedWords,
    required double avgDifficulty,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final total = masteredWords.length + missedWords.length;
    final correct = masteredWords.length;

    final performance = _calculatePerformanceScore(
      correct: correct,
      total: total,
      avgDifficulty: avgDifficulty,
    );

    final habit = await _calculateHabitScore(
      performanceScore: performance,
    );

    final finalScore = _calculateFinalScore(performance, habit);

    final result = QuizResult(
      date: DateTime.now().toIso8601String().substring(0, 10),
      totalWords: total,
      correctWords: correct,
      missedWords: missedWords,
      masteredWords: masteredWords,
      performanceScore: performance,
      habitScore: habit,
      finalScore: finalScore,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    await prefs.setString(_keyPendingResult, jsonEncode(result.toMap()));
    await prefs.setString(_keyLastResult, jsonEncode(result.toMap()));
    await prefs.setString(_keyLastQuizDate, DateTime.now().toIso8601String());

    final currentMissed = prefs.getStringList('stat_missed_words') ?? [];

    final updatedMissed = currentMissed
        .where((w) => !masteredWords.contains(w))
        .toList();

    await prefs.setStringList('stat_missed_words', updatedMissed);
    await prefs.setInt(_keyMissedBaseline, updatedMissed.length);

    final results = prefs.getStringList(_keyQuizResults) ?? [];
    results.add(jsonEncode(result.toMap()));
    await prefs.setStringList(_keyQuizResults, results);

    await _checkAndSaveMonthlyScore(prefs);

    return result;
  }

  // =========================
  // LAST RESULT
  // =========================

  static Future<Map<String, dynamic>?> getLastQuizResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastResult);

    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // =========================
  // RESET
  // =========================

  static Future<void> clearAllQuizData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyQuizResults);
    await prefs.remove(_keyPendingResult);
    await prefs.remove(_keyLastResult);
    await prefs.remove(_keyLastQuizDate);

    await prefs.remove(_keyHabitScore);
    await prefs.remove(_keyHabitLastUpdate);
    await prefs.remove(_keyMissedBaseline);
  }

  // =========================
  // MONTHLY / YEARLY
  // =========================

  static Future<void> _checkAndSaveMonthlyScore(
      SharedPreferences prefs) async {
    final resultsRaw = prefs.getStringList(_keyQuizResults) ?? [];
    if (resultsRaw.isEmpty) return;

    final results =
        resultsRaw.map((r) => QuizResult.fromMap(jsonDecode(r))).toList();
    final currentMonth = DateTime.now().toIso8601String().substring(0, 7);

    // Separate results from past months vs current month
    final pastResults =
        results.where((r) => r.date.substring(0, 7) != currentMonth).toList();
    final currentResults =
        results.where((r) => r.date.substring(0, 7) == currentMonth).toList();

    // Archive past months (regardless of count) and current month if 4+ quizzes
    final shouldArchivePast = pastResults.isNotEmpty;
    final shouldArchiveCurrent = currentResults.length >= 4;
    if (!shouldArchivePast && !shouldArchiveCurrent) return;

    final monthlyRaw = prefs.getStringList(_keyMonthlyScores) ?? [];

    // Group past results by month and archive each
    if (shouldArchivePast) {
      final byMonth = <String, List<QuizResult>>{};
      for (final r in pastResults) {
        byMonth.putIfAbsent(r.date.substring(0, 7), () => []).add(r);
      }
      for (final entry in byMonth.entries) {
        final alreadyExists = monthlyRaw
            .any((m) => (jsonDecode(m) as Map)['monthYear'] == entry.key);
        if (alreadyExists) continue;
        final group = entry.value;
        final monthly = MonthlyScore(
          monthYear: entry.key,
          avgPerformance: group
                  .map((r) => r.performanceScore)
                  .reduce((a, b) => a + b) /
              group.length,
          avgHabit:
              group.map((r) => r.habitScore).reduce((a, b) => a + b) /
                  group.length,
          avgFinal:
              group.map((r) => r.finalScore).reduce((a, b) => a + b) /
                  group.length,
          totalWordsReviewed:
              group.map((r) => r.totalWords).reduce((a, b) => a + b),
          quizzesTaken: group.length,
        );
        monthlyRaw.add(jsonEncode(monthly.toMap()));
      }
    }

    // Archive current month if it hit the 4-quiz threshold
    if (shouldArchiveCurrent) {
      final alreadyExists = monthlyRaw
          .any((m) => (jsonDecode(m) as Map)['monthYear'] == currentMonth);
      if (!alreadyExists) {
        final monthly = MonthlyScore(
          monthYear: currentMonth,
          avgPerformance: currentResults
                  .map((r) => r.performanceScore)
                  .reduce((a, b) => a + b) /
              currentResults.length,
          avgHabit: currentResults
                  .map((r) => r.habitScore)
                  .reduce((a, b) => a + b) /
              currentResults.length,
          avgFinal: currentResults
                  .map((r) => r.finalScore)
                  .reduce((a, b) => a + b) /
              currentResults.length,
          totalWordsReviewed: currentResults
              .map((r) => r.totalWords)
              .reduce((a, b) => a + b),
          quizzesTaken: currentResults.length,
        );
        monthlyRaw.add(jsonEncode(monthly.toMap()));
      }
    }

    await prefs.setStringList(_keyMonthlyScores, monthlyRaw);

    // Keep only current-month results that weren't archived
    final toKeep = shouldArchiveCurrent ? <QuizResult>[] : currentResults;
    await prefs.setStringList(
        _keyQuizResults, toKeep.map((r) => jsonEncode(r.toMap())).toList());

    await _checkAndSaveYearlyScore(prefs);
  }

  static Future<void> _checkAndSaveYearlyScore(
      SharedPreferences prefs) async {
    final monthlyRaw = prefs.getStringList(_keyMonthlyScores) ?? [];

    if (monthlyRaw.length < 12) return;

    final year = DateTime.now().year.toString();

    final yearlyRaw = prefs.getStringList(_keyYearlyScores) ?? [];

    final exists = yearlyRaw.any((y) {
      final map = jsonDecode(y);
      return map['year'] == year;
    });

    if (exists) return;

    final scores =
        monthlyRaw.map((m) => MonthlyScore.fromMap(jsonDecode(m))).toList();

    final yearly = YearlyScore(
      year: year,
      avgPerformance:
          scores.map((s) => s.avgPerformance).reduce((a, b) => a + b) /
              scores.length,
      avgHabit:
          scores.map((s) => s.avgHabit).reduce((a, b) => a + b) /
              scores.length,
      avgFinal:
          scores.map((s) => s.avgFinal).reduce((a, b) => a + b) /
              scores.length,
      totalWordsReviewed:
          scores.map((s) => s.totalWordsReviewed).reduce((a, b) => a + b),
      monthsTracked: scores.length,
    );

    yearlyRaw.add(jsonEncode(yearly.toMap()));

    await prefs.setStringList(_keyYearlyScores, yearlyRaw);
    await prefs.setStringList(_keyMonthlyScores, []);
  }

  // =========================
  // FEEDBACK
  // =========================

  static String getQuizFeedback(double accuracy) {
    if (accuracy >= 1.0) {
      return 'flawless 🌟 okay you might actually be built different';
    }

    if (accuracy >= 0.8) {
      return 'really solid 🎯 a few still haunting you but you\'re getting there 👻';
    }

    if (accuracy >= 0.6) {
      return 'not bad 📈 the hard ones are still giving you trouble though';
    }

    if (accuracy >= 0.4) {
      return 'rough one 😔 but you showed up and that\'s what matters 🌱';
    }

    return 'these words really said no 👻 they\'ll be back. so will you 🔥';
  }
}