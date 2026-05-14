class QuizResult {
  final String date;
  final int totalWords;
  final int correctWords;
  final List<String> missedWords;
  final List<String> masteredWords;
  final double performanceScore;
  final double habitScore;
  final double finalScore;
  final DateTime expiresAt;

  QuizResult({
    required this.date,
    required this.totalWords,
    required this.correctWords,
    required this.missedWords,
    required this.masteredWords,
    required this.performanceScore,
    required this.habitScore,
    required this.finalScore,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'totalWords': totalWords,
        'correctWords': correctWords,
        'missedWords': missedWords.join(','),
        'masteredWords': masteredWords.join(','),
        'performanceScore': performanceScore,
        'habitScore': habitScore,
        'finalScore': finalScore,
        'expiresAt': expiresAt.toIso8601String(),
      };

  static List<String> _parseWordList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final s = value.toString();
    if (s.isEmpty) return [];
    return s.split(',').where((e) => e.isNotEmpty).toList();
  }

  static QuizResult fromMap(Map<String, dynamic> map) => QuizResult(
        date: map['date'],
        totalWords: map['totalWords'],
        correctWords: map['correctWords'],

        missedWords: _parseWordList(map['missedWords']),
        masteredWords: _parseWordList(map['masteredWords']),

        performanceScore:
            (map['performanceScore'] as num).toDouble(),

        habitScore:
            (map['habitScore'] as num).toDouble(),

        finalScore:
            (map['finalScore'] as num).toDouble(),

        expiresAt: DateTime.parse(map['expiresAt']),
      );
}