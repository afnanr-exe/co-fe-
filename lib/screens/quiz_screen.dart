import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_result.dart';
import '../models/word.dart';
import '../services/quiz_service.dart';
import '../services/word_service.dart';

class QuizScreen extends StatefulWidget {
  final List<String> missedWords;

  const QuizScreen({
    super.key,
    required this.missedWords,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Word> _quizWords = [];
  List<List<String>> _choices = [];
  bool _loading = true;

  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;

  final List<String> _mastered = [];
  final List<String> _stillMissed = [];

  @override
  void initState() {
    super.initState();
    _buildQuiz();
  }

  Future<void> _buildQuiz() async {
    final allWords = await WordService.getWords();
    final allTerms = allWords.map((w) => w.term).toSet();

    // Remove missed words that no longer exist in the current word list
    final validMissed = widget.missedWords
        .where((term) => allTerms.contains(term))
        .toList();

    if (validMissed.length != widget.missedWords.length) {
      final prefs =
          await SharedPreferences.getInstance();
      await prefs.setStringList(
          'stat_missed_words', validMissed);
    }

    final matched = allWords
        .where((w) => validMissed.contains(w.term))
        .take(1)
        .toList();

    final choices = matched.map((word) {
      final options = [
        word.definition,
        ...word.distractors,
      ]..shuffle();
      return options;
    }).toList();

    setState(() {
      _quizWords = matched;
      _choices = choices;
      _loading = false;
    });
  }

  Word get _currentWord => _quizWords[_currentIndex];

  bool _isCorrect(int index) {
    return _choices[_currentIndex][index] ==
        _currentWord.definition;
  }

  void _onChoiceTapped(int index) {
    if (_answered) return;

    setState(() {
      _selectedIndex = index;
      _answered = true;
    });

    if (_isCorrect(index)) {
      if (!_mastered.contains(_currentWord.term)) {
        _mastered.add(_currentWord.term);
      }
    } else {
      if (!_stillMissed.contains(_currentWord.term)) {
        _stillMissed.add(_currentWord.term);
      }
    }

    Future.delayed(
      Duration(
        milliseconds: _isCorrect(index) ? 1000 : 1500,
      ),
      _nextWord,
    );
  }

  void _nextWord() {
    if (_currentIndex + 1 >= _quizWords.length) {
      _finishQuiz();
      return;
    }

    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  Future<void> _finishQuiz() async {
    if (_quizWords.isEmpty) return;

    final avgDifficulty =
        _quizWords
                .map((w) => w.difficultyTier.toDouble())
                .reduce((a, b) => a + b) /
            _quizWords.length;

    final result = await QuizService.saveQuizResult(
      masteredWords: _mastered,
      missedWords: _stillMissed,
      avgDifficulty: avgDifficulty,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      _slideRoute(
        QuizResultScreen(result: result),
      ),
    );
  }

  void _goBackToStats() {
    Navigator.of(context).pop();
  }

  Color _getBorderColor(int index) {
    if (!_answered) {
      return _selectedIndex == index
          ? Colors.white
          : Colors.grey.shade800;
    }

    if (_isCorrect(index)) return Colors.green;

    if (_selectedIndex == index && !_isCorrect(index)) {
      return Colors.red;
    }

    return Colors.grey.shade800;
  }

  Color _getTextColor(int index) {
    if (!_answered) {
      return _selectedIndex == index
          ? Colors.white
          : Colors.grey;
    }

    if (_isCorrect(index)) return Colors.green;

    if (_selectedIndex == index && !_isCorrect(index)) {
      return Colors.red;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_quizWords.isEmpty) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _goBackToStats,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade800,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'no words to quiz on yet 👻',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _goBackToStats,
                          child: Container(
                            padding:
                                const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    Colors.grey.shade800,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Weekly Quiz',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_currentIndex + 1} of ${_quizWords.length}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:
                        (_currentIndex + 1) /
                            _quizWords.length,
                    backgroundColor:
                        Colors.grey.shade800,
                    valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(Colors.white),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'What does this word mean?',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentWord.term,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _currentWord.partOfSpeech,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Difficulty: ${_currentWord.difficultyTier}/5',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                ...List.generate(
                  _choices[_currentIndex].length,
                  (index) {
                    return GestureDetector(
                      onTap: () =>
                          _onChoiceTapped(index),
                      child: Container(
                        width: double.infinity,
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _getBorderColor(index),
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                        child: Text(
                          _choices[_currentIndex]
                              [index],
                          style: TextStyle(
                            color:
                                _getTextColor(index),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder:
        (context, animation, secondaryAnimation) =>
            page,
    transitionsBuilder:
        (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween =
              Tween(
                begin: begin,
                end: end,
              ).chain(
                CurveTween(curve: curve),
              );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
    transitionDuration:
        const Duration(milliseconds: 300),
  );
}

class QuizResultScreen extends StatelessWidget {
  final QuizResult result;

  const QuizResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = result.totalWords == 0
        ? 0.0
        : result.correctWords / result.totalWords;
    final feedback = QuizService.getQuizFeedback(accuracy);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade800,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'QUIZ COMPLETE',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feedback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _scoreCard(
                      '🎯 Performance',
                      result.performanceScore.round().toString(),
                    ),
                    const SizedBox(width: 8),
                    _scoreCard(
                      '🔥 Habit',
                      result.habitScore.round().toString(),
                    ),
                    const SizedBox(width: 8),
                    _scoreCard(
                      '⭐ Final',
                      result.finalScore.round().toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade800,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.correctWords} of ${result.totalWords} correct',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (result.masteredWords.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Mastered',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...result.masteredWords.map(
                          (w) => _wordRow(context, w, Colors.green, Icons.check_circle),
                        ),
                      ],
                      if (result.missedWords.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Still tricky',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...result.missedWords.map(
                          (w) => _wordRow(context, w, Colors.red, Icons.cancel),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wordRow(
    BuildContext context,
    String word,
    Color color,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: word));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied "$word"'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.copy,
              color: Colors.grey.shade700,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(String label, String value) {
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
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
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
}
