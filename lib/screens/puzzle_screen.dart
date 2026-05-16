import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/stats_service.dart';
import '../services/word_service.dart';
import '../utils/date_utils.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with WidgetsBindingObserver {
  List<Word> _allWords = [];

  late Word currentWord;
  late List<String> choices;

  int? selectedIndex;

  bool answered = false;
  bool hintRevealed = false;
  bool _loading = true;
  bool _completedToday = false;
  String _loadedDate = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (today != _loadedDate) _init();
    }
  }

  Future<void> _init() async {
    _loadedDate = DateTime.now().toIso8601String().substring(0, 10);
    final words = await WordService.getWords();
    final completed =
        await StatsService.isPuzzleCompletedToday();

    setState(() {
      _allWords = words;
      _completedToday = completed;
      _loading = false;
    });

    _loadWord();
  }

  void _loadWord() {
    if (_allWords.isEmpty) return;

    final today = DateTime.now();

    final index =
        today.dayOfYear % _allWords.length;

    currentWord = _allWords[index];

    choices = [
      currentWord.definition,
      ...currentWord.distractors,
    ]..shuffle();

    selectedIndex = null;
    answered = _completedToday;
    hintRevealed = _completedToday;
  }

  void _onChoiceTapped(int index) {
    if (answered) return;

    setState(() {
      selectedIndex = index;
    });
  }

  void _onConfirm() {
    if (selectedIndex == null || answered) {
      return;
    }

    setState(() {
      answered = true;
    });

    final correct =
        _isCorrect(selectedIndex!);

    StatsService.saveResult(
      wordTerm: currentWord.term,
      correct: correct,
      usedHint: hintRevealed,
    );
  }

  bool _isCorrect(int index) {
    return choices[index] ==
        currentWord.definition;
  }

  void _showHintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            const Color(0xFF1A1A1A),
        title: const Text(
          'Use hint?',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        content: const Text(
          'This will reveal the etymology of the word. Are you sure?',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                hintRevealed = true;
              });
            },
            child: const Text(
              'Yes, show hint',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(int index) {
    if (!answered &&
        selectedIndex == index) {
      return Colors.white;
    }

    if (answered) {
      if (_isCorrect(index)) {
        return Colors.green;
      }

      if (selectedIndex == index &&
          !_isCorrect(index)) {
        return Colors.red;
      }
    }

    return Colors.grey.shade800;
  }

  Color _getTextColor(int index) {
    if (!answered &&
        selectedIndex == index) {
      return Colors.white;
    }

    if (answered) {
      if (_isCorrect(index)) {
        return Colors.green;
      }

      if (selectedIndex == index &&
          !_isCorrect(index)) {
        return Colors.red;
      }
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0A0A0A),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0A0A0A),

        title: const Text(
          'Daily Puzzle',
          style: TextStyle(
            color: Colors.white,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: Colors.grey,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor:
                    const Color(0xFF1A1A1A),

                shape:
                    const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),

                builder: (context) =>
                    const Padding(
                  padding:
                      EdgeInsets.all(24.0),

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        '🧩 Daily Puzzle',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 16),

                      Text(
                        'pick the right definition and confirm ✅',

                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'used a hint? cute, that\'s assisted 😑',

                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'got it wrong? it gets saved so it can haunt you later 👻',

                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),

        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _allWords.isEmpty
              ? const Center(
                  child: Text(
                    'no words loaded',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24.0),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'What does this word mean?',

                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    currentWord.term,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        currentWord
                            .partOfSpeech,

                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontStyle:
                              FontStyle
                                  .italic,
                        ),
                      ),

                      const SizedBox(
                          width: 12),

                      Text(
                        'Difficulty: ${currentWord.difficultyTier}/5',

                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  if (_completedToday)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        bottom: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade800,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'already played today 🧩 come back tomorrow',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  ...List.generate(
                    choices.length,
                    (index) {
                      return GestureDetector(
                        onTap: () =>
                            _onChoiceTapped(
                                index),

                        child: Container(
                          width:
                              double.infinity,

                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),

                          padding:
                              const EdgeInsets
                                  .all(16),

                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  _getBorderColor(
                                      index),
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                                        12),
                          ),

                          child: Text(
                            choices[index],

                            style:
                                TextStyle(
                              color:
                                  _getTextColor(
                                      index),

                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  if (hintRevealed ||
                      answered)
                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .all(16),

                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),

                      decoration:
                          BoxDecoration(
                        border: Border.all(
                          color: Colors
                              .grey.shade800,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(12),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Text(
                            'Etymology',

                            style: TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(
                              height: 4),

                          Text(
                            currentWord
                                .etymology,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (answered)
                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .all(16),

                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),

                      decoration:
                          BoxDecoration(
                        border: Border.all(
                          color: Colors
                              .grey.shade800,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(12),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Text(
                            'Pronunciation',

                            style: TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(
                              height: 4),

                          Text(
                            currentWord
                                .pronunciation,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              letterSpacing:
                                  1.2,
                            ),
                          ),

                          const SizedBox(
                              height: 12),

                          const Text(
                            'Used in a sentence',

                            style: TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(
                              height: 4),

                          Text(
                            currentWord
                                .exampleSentence,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 14,
                              fontStyle:
                                  FontStyle
                                      .italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!answered)
                    Row(
                      children: [
                        Expanded(
                          child:
                              GestureDetector(
                            onTap:
                                selectedIndex !=
                                        null
                                    ? _onConfirm
                                    : null,

                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 16,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    selectedIndex !=
                                            null
                                        ? Colors
                                            .white
                                        : Colors
                                            .grey
                                            .shade900,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            12),
                              ),

                              alignment:
                                  Alignment
                                      .center,

                              child: Text(
                                'Confirm',

                                style:
                                    TextStyle(
                                  color:
                                      selectedIndex !=
                                              null
                                          ? Colors
                                              .black
                                          : Colors
                                              .grey,

                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (!hintRevealed)
                          ...[
                            const SizedBox(
                                width: 12),

                            GestureDetector(
                              onTap:
                                  _showHintDialog,

                              child:
                                  Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 16,
                                  horizontal:
                                      20,
                                ),

                                decoration:
                                    BoxDecoration(
                                  border:
                                      Border.all(
                                    color: Colors
                                        .grey
                                        .shade800,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              12),
                                ),

                                child:
                                    const Text(
                                  'Hint',

                                  style:
                                      TextStyle(
                                    color: Colors
                                        .grey,
                                    fontSize:
                                        15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                      ],
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}