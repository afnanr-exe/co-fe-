import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class DictionaryService {
  static const _freeBase = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  static const _mwBase =
      'https://www.dictionaryapi.com/api/v3/references/collegiate/json';

  // Look up a single word. Tries MW first if key provided, then free API.
  static Future<Map<String, String>?> lookup(
    String term, {
    String? mwKey,
  }) async {
    try {
      if (mwKey != null && mwKey.isNotEmpty) {
        final mw = await _lookupMW(term, mwKey);
        if (mw != null) return mw;
      }
      return await _lookupFree(term);
    } catch (_) {
      return null;
    }
  }

  // Look up a list of words in batches of 8 concurrent requests.
  static Future<List<Map<String, String>?>> lookupBatch(
    List<String> terms, {
    String? mwKey,
    void Function(int done, int total)? onProgress,
  }) async {
    const batchSize = 8;
    final results = <Map<String, String>?>[];

    for (int i = 0; i < terms.length; i += batchSize) {
      final batch = terms.sublist(i, min(i + batchSize, terms.length));
      final batchResults = await Future.wait(
        batch.map((t) => lookup(t, mwKey: mwKey)),
      );
      results.addAll(batchResults);
      onProgress?.call(results.length, terms.length);
    }

    return results;
  }

  // Test that a MW key is valid by looking up a known word.
  static Future<bool> verifyMWKey(String key) async {
    final result = await _lookupMW('serendipity', key);
    return result != null;
  }

  // ---------------------------------------------------------------------------
  // Free Dictionary API
  // ---------------------------------------------------------------------------

  static Future<Map<String, String>?> _lookupFree(String term) async {
    final uri = Uri.parse('$_freeBase/${Uri.encodeComponent(term.toLowerCase())}');
    final response =
        await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data is! List || data.isEmpty) return null;

    final entry = data[0] as Map<String, dynamic>;
    final meanings = entry['meanings'] as List? ?? [];
    if (meanings.isEmpty) return null;

    final firstMeaning = meanings[0] as Map<String, dynamic>;
    final defs = firstMeaning['definitions'] as List? ?? [];
    if (defs.isEmpty) return null;

    final firstDef = defs[0] as Map<String, dynamic>;
    final definition = firstDef['definition'] as String? ?? '';
    if (definition.isEmpty) return null;

    // Try to find an example sentence across all meanings
    String example = '';
    outer:
    for (final m in meanings) {
      for (final d in (m as Map)['definitions'] as List? ?? []) {
        final ex = (d as Map)['example'] as String?;
        if (ex != null && ex.isNotEmpty) {
          example = ex;
          break outer;
        }
      }
    }

    return {
      'definition': definition,
      'partOfSpeech': firstMeaning['partOfSpeech'] as String? ?? 'unknown',
      'pronunciation': _extractFreePhonetic(entry) ?? term,
      'exampleSentence': example.isNotEmpty
          ? example
          : 'No example sentence available.',
      'etymology': '',
    };
  }

  static String? _extractFreePhonetic(Map<String, dynamic> entry) {
    final phonetic = entry['phonetic'] as String?;
    if (phonetic != null && phonetic.isNotEmpty) return phonetic;
    final phonetics = entry['phonetics'] as List? ?? [];
    for (final p in phonetics) {
      final text = (p as Map)['text'] as String?;
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Merriam-Webster Collegiate API
  // ---------------------------------------------------------------------------

  static Future<Map<String, String>?> _lookupMW(
      String term, String key) async {
    final uri = Uri.parse(
        '$_mwBase/${Uri.encodeComponent(term.toLowerCase())}?key=$key');
    final response =
        await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data is! List || data.isEmpty) return null;
    // MW returns a list of strings (suggestions) when the word isn't found
    if (data[0] is String) return null;

    final entry = data[0] as Map<String, dynamic>;

    final pos = entry['fl'] as String? ?? 'unknown';
    final pronunciation = _extractMWPronunciation(entry);
    final definition = _extractMWDefinition(entry);
    if (definition.isEmpty) return null;

    return {
      'definition': definition,
      'partOfSpeech': pos,
      'pronunciation': pronunciation ?? term,
      'exampleSentence': _extractMWExample(entry),
      'etymology': _extractMWEtymology(entry),
    };
  }

  static String? _extractMWPronunciation(Map<String, dynamic> entry) {
    final hwi = entry['hwi'] as Map<String, dynamic>?;
    final prs = hwi?['prs'] as List?;
    if (prs == null || prs.isEmpty) return null;
    return (prs[0] as Map)['mw'] as String?;
  }

  static String _extractMWDefinition(Map<String, dynamic> entry) {
    final defs = entry['def'] as List?;
    if (defs == null || defs.isEmpty) return '';
    final sseq = (defs[0] as Map)['sseq'] as List?;
    if (sseq == null || sseq.isEmpty) return '';

    for (final senseGroup in sseq) {
      for (final sense in (senseGroup as List)) {
        if (sense is List && sense.length > 1 && sense[1] is Map) {
          final dt = (sense[1] as Map)['dt'] as List?;
          if (dt == null) continue;
          for (final item in dt) {
            if (item is List && item[0] == 'text') {
              final text = _stripMW(item[1] as String);
              if (text.isNotEmpty) return text;
            }
          }
        }
      }
    }
    return '';
  }

  static String _extractMWExample(Map<String, dynamic> entry) {
    final defs = entry['def'] as List? ?? [];
    for (final def in defs) {
      final sseq = (def as Map)['sseq'] as List? ?? [];
      for (final senseGroup in sseq) {
        for (final sense in (senseGroup as List)) {
          if (sense is List && sense.length > 1 && sense[1] is Map) {
            final dt = (sense[1] as Map)['dt'] as List? ?? [];
            for (final item in dt) {
              if (item is List && item[0] == 'vis') {
                final vis = item[1] as List?;
                if (vis != null && vis.isNotEmpty) {
                  final t = (vis[0] as Map)['t'] as String?;
                  if (t != null && t.isNotEmpty) return _stripMW(t);
                }
              }
            }
          }
        }
      }
    }
    return 'No example sentence available.';
  }

  static String _extractMWEtymology(Map<String, dynamic> entry) {
    final et = entry['et'] as List?;
    if (et == null || et.isEmpty) return '';
    final first = et[0];
    if (first is List && first.length > 1 && first[0] == 'text') {
      return _stripMW(first[1] as String);
    }
    return '';
  }

  // Strip all Merriam-Webster curly-brace markup tags.
  static String _stripMW(String text) {
    return text
        .replaceAll('{bc}', ': ')
        .replaceAll('{ldquo}', '"')
        .replaceAll('{rdquo}', '"')
        .replaceAll('{amp}', '&')
        .replaceAll(RegExp(r'\{[^}]*\}'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
