import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/quiz_result.dart';
import '../services/stats_service.dart';
import '../services/quiz_service.dart';
import 'quiz_screen.dart';

PageRouteBuilder _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic> _stats = {
    'correct': 0,
    'assisted': 0,
    'wrong': 0,
    'streak': 0,
    'bestStreak': 0,
    'missedWords': [],
    'weeklyActivity': {},
  };
  bool _quizReady = false;
  bool _inCooldown = false;
  Map<String, dynamic>? _lastQuizResult;
  int _mistakesUntilQuiz = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await StatsService.getStats();
    final quizReady = await QuizService.isQuizReady();
    final inCooldown = await QuizService.isInCooldown();
    final lastQuiz = await QuizService.getLastQuizResult();
    final mistakesNeeded = await QuizService.mistakesUntilQuiz();
    setState(() {
      _stats = stats;
      _quizReady = quizReady;
      _inCooldown = inCooldown;
      _lastQuizResult = lastQuiz;
      _mistakesUntilQuiz = mistakesNeeded;
    });
  }

  int get _totalPlayed =>
      _stats['correct'] + _stats['assisted'] + _stats['wrong'];

  double get _accuracy {
    if (_totalPlayed == 0) return 0;
    return (_stats['correct'] + _stats['assisted']) / _totalPlayed;
  }

  double get _puzzleScore {
    if (_totalPlayed == 0) return 0;
    final weighted =
        _stats['correct'] + (_stats['assisted'] as int) * 0.5;
    return (weighted / _totalPlayed * 100).clamp(0.0, 100.0);
  }


  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 Your Stats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '🟢 you got it',
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 8),
            Text(
              '🟡 you got it with a hint... yawn 🥱',
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 8),
            Text(
              '🔴 you didn\'t 😔',
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 8),
            Text(
              'streak is days in a row 🔥',
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getWeekDays() {
    final today = DateTime.now();
    final activity = _stats['weeklyActivity'] as Map<dynamic, dynamic>? ?? {};
    // weekday: 1=Mon…7=Sun → daysSinceSunday: Sun=0, Mon=1…Sat=6
    final daysSinceSunday = today.weekday % 7;
    final sunday = today.subtract(Duration(days: daysSinceSunday));
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return List.generate(7, (i) {
      final day = sunday.add(Duration(days: i));
      final key = day.toIso8601String().substring(0, 10);
      final result = activity[key];
      final isToday = day.year == today.year &&
          day.month == today.month &&
          day.day == today.day;
      return {
        'day': labels[i],
        'result': result,
        'isToday': isToday,
      };
    });
  }

  Color _dotColor(String? result) {
    switch (result) {
      case 'correct':
        return Colors.green;
      case 'assisted':
        return Colors.amber;
      case 'wrong':
        return Colors.red;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final missed = _stats['missedWords'] as List<dynamic>;
    final weekDays = _getWeekDays();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Stats',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showInfo(context),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_quizReady)
                GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final missedWords =
                        prefs.getStringList('stat_missed_words') ?? [];
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        _slideRoute(QuizScreen(missedWords: missedWords)),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      border: Border.all(color: Colors.blue.shade800),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('👻', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'weekly quiz ready — ${missed.length} words waiting',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.grey, size: 14),
                      ],
                    ),
                  ),
                )
              else if (_inCooldown && _lastQuizResult != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      _slideRoute(QuizResultScreen(
                        result: QuizResult.fromMap(_lastQuizResult!),
                      )),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2E1A),
                      border: Border.all(color: Colors.green.shade800),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('🧠', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'quiz results',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              const Text(
                                'get 3 more wrong answers to unlock',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.grey, size: 14),
                      ],
                    ),
                  ),
                ),
              if (!_quizReady && _mistakesUntilQuiz > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_mistakesUntilQuiz more wrong answer${_mistakesUntilQuiz == 1 ? '' : 's'} needed to unlock quiz',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade800),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔥 Streak',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 12),
                          Text(
                            '${_stats['streak']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          const Text('days',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(
                            'Best: ${_stats['bestStreak']}d',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade800),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🎯 Accuracy',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 12),
                          Center(
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: CustomPaint(
                                painter: _RingPainter(
                                  correct: _stats['correct'],
                                  assisted: _stats['assisted'],
                                  wrong: _stats['wrong'],
                                  total: _totalPlayed,
                                ),
                                child: Center(
                                  child: Text(
                                    _totalPlayed == 0
                                        ? '—'
                                        : '${(_accuracy * 100).round()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🧩 Puzzle Score',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _totalPlayed == 0
                              ? '—'
                              : '${_puzzleScore.round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_totalPlayed > 0)
                          const Text(
                            ' /100',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_lastQuizResult != null) ...[
                Row(
                  children: [
                    _buildScoreCard(
                      '🎯 Performance',
                      (_lastQuizResult!['performanceScore'] as num)
                          .round()
                          .toString(),
                    ),
                    const SizedBox(width: 8),
                    _buildScoreCard(
                      '🔥 Habit',
                      (_lastQuizResult!['habitScore'] as num)
                          .round()
                          .toString(),
                    ),
                    const SizedBox(width: 8),
                    _buildScoreCard(
                      '⭐ Final',
                      (_lastQuizResult!['finalScore'] as num)
                          .round()
                          .toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      _slideRoute(QuizResultScreen(
                        result: QuizResult.fromMap(_lastQuizResult!),
                      )),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'last quiz — ${_lastQuizResult!['date']}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.grey, size: 13),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This week',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: weekDays.map((d) {
                        final isToday = d['isToday'] as bool;
                        return Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _dotColor(d['result']),
                                shape: BoxShape.circle,
                                border: isToday
                                    ? Border.all(
                                        color: Colors.white, width: 2)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              d['day'],
                              style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total played',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 14)),
                    Text(
                      '$_totalPlayed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildResultCard('Correct', _stats['correct'],
                      const Color(0xFF1A3A1A), Colors.green),
                  const SizedBox(width: 8),
                  _buildResultCard('Assisted', _stats['assisted'],
                      const Color(0xFF3A2E00), Colors.amber),
                  const SizedBox(width: 8),
                  _buildResultCard('Wrong', _stats['wrong'],
                      const Color(0xFF3A1A1A), Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              if (_totalPlayed > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Breakdown',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            if (_stats['correct'] > 0)
                              Expanded(
                                flex: _stats['correct'],
                                child: Container(
                                    height: 10, color: Colors.green),
                              ),
                            if (_stats['assisted'] > 0)
                              Expanded(
                                flex: _stats['assisted'],
                                child: Container(
                                    height: 10, color: Colors.amber),
                              ),
                            if (_stats['wrong'] > 0)
                              Expanded(
                                flex: _stats['wrong'],
                                child: Container(
                                    height: 10, color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildLegend(Colors.green, 'Correct'),
                          const SizedBox(width: 16),
                          _buildLegend(Colors.amber, 'Assisted'),
                          const SizedBox(width: 16),
                          _buildLegend(Colors.red, 'Wrong'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (missed.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Words to review',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${missed.length}',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...missed.map((word) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              word.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
      String label, int value, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}


class _RingPainter extends CustomPainter {
  final int correct;
  final int assisted;
  final int wrong;
  final int total;

  _RingPainter({
    required this.correct,
    required this.assisted,
    required this.wrong,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (total == 0) return;

    final correctAngle = (correct / total) * 2 * pi;
    final assistedAngle = (assisted / total) * 2 * pi;
    final wrongAngle = (wrong / total) * 2 * pi;

    double startAngle = -pi / 2;

    void drawArc(double sweep, Color color) {
      if (sweep <= 0) return;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }

    drawArc(correctAngle, Colors.green);
    drawArc(assistedAngle, Colors.amber);
    drawArc(wrongAngle, Colors.red);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}