import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../utils/date_utils.dart';

class WordOfTheDayScreen extends StatefulWidget {
  const WordOfTheDayScreen({super.key});

  @override
  State<WordOfTheDayScreen> createState() =>
      _WordOfTheDayScreenState();
}

class _WordOfTheDayScreenState
    extends State<WordOfTheDayScreen>
    with WidgetsBindingObserver {
  Word? _word;
  bool _loading = true;
  String _loadedDate = '';
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWord();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = tomorrow.difference(now);
    _midnightTimer = Timer(untilMidnight, () {
      _loadWord();
      _scheduleMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (today != _loadedDate) _loadWord();
    }
  }

  Future<void> _loadWord() async {
    _loadedDate = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final words = await WordService.getWords();

      if (words.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final today = DateTime.now();
      // offset +14 so today's WotD matches the puzzle word 14 days from now
      final index = (today.dayOfYear + 14) % words.length;
      final word = words[index];

      if (mounted) setState(() {
        _word = word;
        _loading = false;
      });

      try {
        await _pushWidgetData(word);
      } catch (_) {}
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pushWidgetData(Word word) async {
    await HomeWidget.saveWidgetData('widget_word_term', word.term);
    await HomeWidget.saveWidgetData('widget_word_pos', word.partOfSpeech);
    await HomeWidget.saveWidgetData('widget_word_definition', word.definition);
    await HomeWidget.updateWidget(androidName: 'WordWidget');
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              '💡 Word of the Day',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'new word every day 📖',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'read it, let it sink in.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'it\'ll show up in the puzzle in 2 weeks — so maybe don\'t skip this one 👀',
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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_word == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: SafeArea(
          child: Center(
            child: Text(
              'no words loaded',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final word = _word!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Word of the Day',
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
              const SizedBox(height: 24),
              Text(
                word.term,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    word.partOfSpeech,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    word.pronunciation,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildCard(
                label: 'Definition',
                content: word.definition,
              ),
              const SizedBox(height: 12),
              _buildCard(
                label: 'Used in a sentence',
                content: word.exampleSentence,
                italic: true,
              ),
              const SizedBox(height: 12),
              _buildCard(
                label: 'Etymology',
                content: word.etymology,
              ),
              const SizedBox(height: 12),
              _buildDifficultyCard(
                word.difficultyTier,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required String content,
    bool italic = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade800,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontStyle: italic
                  ? FontStyle.italic
                  : FontStyle.normal,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard(int tier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade800,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Difficulty',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              return Container(
                width: 40,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: index < tier
                      ? Colors.white
                      : Colors.grey.shade800,
                  borderRadius:
                      BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
