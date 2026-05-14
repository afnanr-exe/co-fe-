class Word {
  final String term;
  final String definition;
  final String exampleSentence;
  final int difficultyTier;
  final String language;
  final String etymology;
  final List<String> distractors;
  final String partOfSpeech;
  final String pronunciation;

  const Word({
    required this.term,
    required this.definition,
    required this.exampleSentence,
    required this.difficultyTier,
    required this.language,
    required this.etymology,
    required this.distractors,
    required this.partOfSpeech,
    required this.pronunciation,
  });
}