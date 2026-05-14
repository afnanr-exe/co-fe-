class YearlyScore {
  final String year;
  final double avgPerformance;
  final double avgHabit;
  final double avgFinal;
  final int totalWordsReviewed;
  final int monthsTracked;

  YearlyScore({
    required this.year,
    required this.avgPerformance,
    required this.avgHabit,
    required this.avgFinal,
    required this.totalWordsReviewed,
    required this.monthsTracked,
  });

  Map<String, dynamic> toMap() => {
        'year': year,
        'avgPerformance': avgPerformance,
        'avgHabit': avgHabit,
        'avgFinal': avgFinal,
        'totalWordsReviewed': totalWordsReviewed,
        'monthsTracked': monthsTracked,
      };

  static YearlyScore fromMap(Map<String, dynamic> map) => YearlyScore(
        year: map['year'],
        avgPerformance: map['avgPerformance'],
        avgHabit: map['avgHabit'],
        avgFinal: map['avgFinal'],
        totalWordsReviewed: map['totalWordsReviewed'],
        monthsTracked: map['monthsTracked'],
      );
}