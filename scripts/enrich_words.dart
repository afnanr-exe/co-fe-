import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const apiKey = 'f267a9dc-2e34-466b-83f3-2d3e55c320dc';

const List<String> wordList = [
  // Coffee sensory
  'aromatic', 'astringent', 'bitter', 'bodied', 'bright',
  'briny', 'caramelized', 'clean', 'complex', 'crisp',
  'delicate', 'dense', 'earthy', 'floral', 'fragrant',
  'fruity', 'grassy', 'herbal', 'honeyed', 'jammy',
  'juicy', 'layered', 'lush', 'mellow', 'mild',
  'musky', 'nutty', 'pungent', 'rich', 'robust',
  'rounded', 'silky', 'smoky', 'smooth', 'spicy',
  'sweet', 'syrupy', 'tangy', 'tart', 'toasty',
  'velvety', 'watery', 'woody', 'aroma', 'blend',
  'brew', 'ceremonial', 'contemplative', 'cozy', 'craft',

  // Coffee atmosphere
  'ephemeral', 'fleeting', 'intimate', 'languid', 'lingering',
  'meditative', 'mindful', 'misty', 'momentary', 'nostalgic',
  'reflective', 'ritual', 'rustic', 'serene', 'solitary',
  'somber', 'subtle', 'temperate', 'tranquil', 'unhurried',
  'wistful', 'ambiance', 'calm', 'dim', 'gentle',
  'peaceful', 'quiet', 'slow', 'still', 'warm',
  'zen', 'morning', 'pensive', 'hushed', 'muted',

  // Tier 2
  'acrid', 'affable', 'blithe', 'candid', 'deft',
  'earnest', 'fervent', 'genial', 'hapless', 'inept',
  'keen', 'lucid', 'nascent', 'opulent', 'quaint',
  'resilient', 'sanguine', 'tenacious', 'urbane', 'valiant',
  'whimsical', 'ebullient', 'jocund', 'mirth', 'brevity',
  'dauntless', 'felicity', 'jubilant', 'nimble', 'pragmatic',
  'winsome', 'zenith', 'gallant', 'empathy', 'diligent',
  'catalyst', 'benevolent', 'accolade', 'optimism', 'nostalgia',

  // Tier 3
  'acrimony', 'banal', 'cacophony', 'diffident', 'eloquent',
  'fastidious', 'garrulous', 'hedonist', 'iconoclast', 'juxtapose',
  'loquacious', 'melancholy', 'nonchalant', 'oblivious', 'pernicious',
  'querulous', 'rancor', 'stoic', 'taciturn', 'umbrage',
  'verbose', 'wane', 'ardent', 'capricious', 'disdain',
  'furtive', 'gregarious', 'hubris', 'insidious', 'jaded',
  'laconic', 'maudlin', 'nebulous', 'obstinate', 'petrichor',
  'reclusive', 'serendipity', 'terse', 'uncanny', 'zealot',
  'cogent', 'erudite', 'gravitas', 'halcyon', 'ineffable',
  'alacrity', 'zeitgeist', 'sanctuary', 'renaissance', 'perseverance',
  'magnanimous', 'luminous', 'kaleidoscope', 'judicious', 'impeccable',
  'watershed', 'venerable', 'unwavering', 'transcend', 'quintessential',
  'haven', 'facetious', 'catharsis', 'glib', 'pariah',
  'wanton', 'acumen', 'usurp', 'yore', 'kerfuffle',

  // Tier 4
  'acerbic', 'bellicose', 'demagogue', 'enervate', 'fatuous',
  'grandiloquent', 'hegemony', 'impetuous', 'jejune', 'lugubrious',
  'machiavellian', 'nugatory', 'obfuscate', 'panacea', 'quixotic',
  'recondite', 'sycophant', 'truculent', 'unctuous', 'vicissitude',
  'bucolic', 'consternation', 'duplicity', 'equivocate', 'fallacious',
  'harangue', 'imbroglio', 'knell', 'lassitude', 'mendacious',
  'nefarious', 'obsequious', 'redolent', 'solipsism', 'turpitude',
  'venal', 'zealotry', 'limpid', 'mercurial', 'ostentatious',
  'rapture', 'scintillating', 'unequivocal', 'verdant', 'abstruse',
  'dalliance', 'enigmatic', 'meticulous', 'tumultuous', 'unabashed',
  'zealous', 'languorous', 'lachrymose', 'harbinger', 'insipid',
  'jaunty', 'kinetic', 'mundane', 'palpable', 'raucous',
  'scrupulous', 'ubiquitous', 'visceral',

  // Tier 5
  'abstemious', 'cacoethes', 'defenestrate', 'florilegia', 'logorrhea',
  'noctilucent', 'omphaloskepsis', 'titivate', 'widdershins', 'borborygmus',
  'callipygian', 'flibbertigibbet', 'hamartia', 'idiolect', 'limerence',
  'nepenthe', 'obnubilate', 'quiddity', 'retronym', 'sonder',
  'velleity',

  // Sensory experience
  'ambrosial', 'balmy', 'bittersweet', 'bracing', 'burnished',
  'celestial', 'clarion', 'coppery', 'crystalline', 'dappled',
  'effervescent', 'enveloping', 'ethereal', 'exquisite', 'faint',
  'gilded', 'gossamer', 'incandescent', 'lapidary', 'luminescent',
  'mellifluous', 'molten', 'opalescent', 'pellucid', 'plangent',
  'poignant', 'prismatic', 'resinous', 'resonant', 'savory',
  'shimmering', 'sibilant', 'sonorous', 'suffused', 'susurrous',
  'tenuous', 'tremulous', 'vaporous', 'iridescent', 'lambent',
  'phosphorescent', 'penumbra', 'scintilla', 'diaphanous',

  // Character and virtue
  'aplomb', 'bravado', 'candor', 'decorum', 'esprit',
  'fortitude', 'guile', 'hauteur', 'ingenue', 'joviality',
  'languor', 'malaise', 'naivete', 'panache', 'rectitude',
  'sagacity', 'timbre', 'verve', 'whimsy', 'acuity',
  'bonhomie', 'clemency', 'dexterity', 'effrontery', 'finesse',
  'humility', 'ire', 'joie', 'largesse', 'mettle',
  'nobility', 'poise', 'qualm', 'reproach', 'suavity',
  'temerity', 'valor', 'wrath', 'aloof', 'brazen',
  'curt', 'demure',

  // Extra backup words
  'abjure', 'accrue', 'adroit', 'aggrandize', 'ameliorate',
  'anomalous', 'antipathy', 'apposite', 'arcane', 'assuage',
  'attenuate', 'augment', 'avarice', 'avid', 'beguile',
  'beleaguer', 'benign', 'bombast', 'boon', 'burgeon',
  'caustic', 'censure', 'chagrin', 'circumspect', 'clamor',
  'coalesce', 'compunction', 'contrition', 'convivial', 'credulous',
  'culpable', 'cupidity', 'cursory', 'cynical', 'debonair',
  'decadent', 'despondent', 'diapason', 'dilettante', 'discern',
  'disparage', 'dissemble', 'doleful', 'dormant', 'dour',
  'draconian', 'ebullience', 'eccentric', 'eclectic',
];

int inferDifficulty(String word, Map<String, dynamic> data) {
  int score = 0;

  final defLength = data['definition'].toString().length;

  if (defLength > 100) {
    score += 2;
  } else if (defLength > 60) {
    score += 1;
  }

  if (data['etymology'] == 'Origin unknown') {
    score += 1;
  }

  final vowels = RegExp(r'[aeiouAEIOU]');
  final syllables = vowels.allMatches(word).length;

  if (syllables >= 5) {
    score += 3;
  } else if (syllables >= 4) {
    score += 2;
  } else if (syllables >= 3) {
    score += 1;
  }

  if (score >= 6) return 5;
  if (score >= 4) return 4;
  if (score >= 3) return 3;
  if (score >= 2) return 2;

  return 1;
}

Future<Map<String, dynamic>?> fetchWord(String word) async {
  try {
    final url =
        'https://www.dictionaryapi.com/api/v3/references/collegiate/json/$word?key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      print('Failed to fetch $word: ${response.statusCode}');
      return null;
    }

    final data = jsonDecode(response.body);

    if (data is! List || data.isEmpty || data[0] is! Map) {
      print('No valid entry for $word');
      return null;
    }

    final entry = data[0] as Map<String, dynamic>;

    String definition = '';

    final def = entry['shortdef'];

    if (def is List && def.isNotEmpty) {
      definition = def[0].toString();
    }

    if (definition.isEmpty) {
      return null;
    }

    String partOfSpeech = entry['fl']?.toString() ?? 'noun';

    String pronunciation = '';

    final hwi = entry['hwi'];

    if (hwi != null &&
        hwi['prs'] is List &&
        hwi['prs'].isNotEmpty) {
      final prs = hwi['prs'][0];

      if (prs['mw'] != null) {
        pronunciation = prs['mw'].toString();
      }
    }

    String etymology = '';

    final et = entry['et'];

    if (et is List &&
        et.isNotEmpty &&
        et[0] is List) {
      final etText = et[0];

      if (etText.length > 1) {
        etymology = etText[1]
            .toString()
            .replaceAll(RegExp(r'\{[^}]*\}'), '')
            .trim();
      }
    }

    final wordData = {
      'term': word,
      'definition': definition,
      'partOfSpeech': partOfSpeech,
      'pronunciation':
          pronunciation.isNotEmpty ? pronunciation : word,
      'etymology':
          etymology.isNotEmpty ? etymology : 'Origin unknown',
      'exampleSentence':
          'The word $word captures something most people feel but rarely say.',
      'language': 'en',
      'distractors': [],
    };

    wordData['difficultyTier'] =
        inferDifficulty(word, wordData);

    return wordData;
  } catch (e) {
    print('Error fetching $word: $e');
    return null;
  }
}

void main() async {
  print('Starting word enrichment for co:fe...');

  final results = <Map<String, dynamic>>[];
  final failed = <String>[];

  // Remove duplicates while preserving order
  final seen = <String>{};

  final uniqueWords = wordList
      .where((word) => seen.add(word))
      .toList();

  print('Unique source words: ${uniqueWords.length}');

  // Fail-safe target
  const targetCount = 365;

  for (int i = 0; i < uniqueWords.length; i++) {
    // Stop once we successfully collect 365
    if (results.length >= targetCount) {
      break;
    }

    final word = uniqueWords[i];

    print(
      'Fetching ${results.length + 1}/$targetCount: $word',
    );

    final result = await fetchWord(word);

    if (result != null) {
      results.add(result);
      print('✓ Added: $word');
    } else {
      failed.add(word);
      print('✗ Failed: $word');
    }

    // Avoid API rate limits
    await Future.delayed(
      const Duration(milliseconds: 150),
    );
  }

  print('\n==============================');
  print('Finished processing');
  print('Successful words: ${results.length}');
  print('Failed words: ${failed.length}');
  print('==============================');

  // Final safety check
  if (results.length < targetCount) {
    print(
      '\nWARNING: Only ${results.length} valid words found.',
    );
    print(
      'Add more backup words to wordList if you need exactly 365.',
    );
  }

  if (failed.isNotEmpty) {
    print('\nFailed words:');
    print(failed.join(', '));
  }

  final output = const JsonEncoder.withIndent('  ')
      .convert(results);

  final file = File('../assets/words.json');

  await file.writeAsString(output);

  print('\nSaved to ../assets/words.json');
}