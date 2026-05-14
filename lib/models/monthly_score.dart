class MonthlyScore {
  final String monthYear;
  final double avgPerformance;
  final double avgHabit;
  final double avgFinal;
  final int totalWordsReviewed;
  final int quizzesTaken;

  MonthlyScore({
    required this.monthYear,
    required this.avgPerformance,
    required this.avgHabit,
    required this.avgFinal,
    required this.totalWordsReviewed,
    required this.quizzesTaken,
  });

  Map<String, dynamic> toMap() => {
        'monthYear': monthYear,
        'avgPerformance': avgPerformance,
        'avgHabit': avgHabit,
        'avgFinal': avgFinal,
        'totalWordsReviewed': totalWordsReviewed,
        'quizzesTaken': quizzesTaken,
      };

  static MonthlyScore fromMap(Map<String, dynamic> map) => MonthlyScore(
        monthYear: map['monthYear'],
        avgPerformance: map['avgPerformance'],
        avgHabit: map['avgHabit'],
        avgFinal: map['avgFinal'],
        totalWordsReviewed: map['totalWordsReviewed'],
        quizzesTaken: map['quizzesTaken'],
      );
}