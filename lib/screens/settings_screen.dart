import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/dictionary_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/word_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _mwKeyController = TextEditingController();

  bool _loading = false;
  String _importStatus = '';
  int _remainingChanges = 3;
  bool _notificationsEnabled = false;
  bool _hasCustomWords = false;

  // MW key state: null = unchecked, true = valid, false = invalid
  bool? _mwKeyValid;
  bool _mwKeyObscured = true;
  bool _verifyingKey = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();

    _loadRemaining();
    _loadNotifPref();
    _loadMWKey();
    _loadCustomWordsFlag();
  }

  Future<void> _loadNotifPref() async {
    final enabled = await NotificationService.isEnabled();
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    try {
      await NotificationService.setEnabled(value);
    } catch (_) {}
  }

  Future<void> _loadMWKey() async {
    final key = await SettingsService.getMWApiKey();
    if (!mounted) return;
    if (key != null) {
      _mwKeyController.text = key;
      setState(() => _mwKeyValid = true);
    }
  }

  Future<void> _saveMWKey() async {
    final key = _mwKeyController.text.trim();
    if (key.isEmpty) {
      try {
        await SettingsService.setMWApiKey('');
      } catch (_) {}
      if (!mounted) return;
      setState(() => _mwKeyValid = null);
      return;
    }

    setState(() => _verifyingKey = true);
    try {
      final valid = await DictionaryService.verifyMWKey(key);
      if (!mounted) return;
      if (valid) await SettingsService.setMWApiKey(key);
      setState(() {
        _mwKeyValid = valid;
        _verifyingKey = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mwKeyValid = false;
        _verifyingKey = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mwKeyController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomWordsFlag() async {
    final has = await WordService.hasCustomWords();
    if (!mounted) return;
    setState(() => _hasCustomWords = has);
  }

  Future<void> _loadRemaining() async {
    final remaining = await SettingsService.remainingChangesToday();

    if (!mounted) return;

    setState(() {
      _remainingChanges = remaining;
    });
  }

  Future<void> _importWords() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _importStatus = 'looking up definitions...';
    });

    final result = await SettingsService.importCustomWords(
      _controller.text,
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() => _importStatus = 'enriching $done / $total words...');
      },
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _importStatus = '';
    });

    await _loadRemaining();
    if (!mounted) return;

    final enriched = (result['enriched'] as int?) ?? 0;
    final msg = result['success'] == true
        ? 'imported ${result['imported']} words'
            '${enriched > 0 ? ' ($enriched enriched with definitions)' : ''}'
        : result['message'] as String;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _revertWords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Revert to original list?',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          'This will replace your current word list with the original 365 words. Your stats and progress are not affected.',
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Revert', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await SettingsService.revertToOriginalWords();
    if (!mounted) return;

    setState(() => _hasCustomWords = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reverted to original word list')),
    );
  }

  Future<void> _exportWords() async {
    final words = await SettingsService.exportWordList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Current Word List',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            words,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Reset everything?',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          'This clears all stats, quiz history, habit score, and missed words. Cannot be undone.',
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    await SettingsService.fullReset();

    if (!mounted) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Widget _langOption({
    required String label,
    required String tag,
    required bool enabled,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Spacer(),
            Text(
              tag,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            if (!enabled) ...[
              const SizedBox(width: 8),
              const Text(
                'coming soon',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _button({
    required String text,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: _loading ? Colors.grey : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          title: const Text(
            'Settings',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ================= CUSTOM WORDS =================
                _section(
                  title: 'Custom Words',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'paste up to 365 words (comma or space separated)',
                          hintStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey.shade800),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // smooth animated counter (fixes flash)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Text(
                          'remaining changes today: $_remainingChanges',
                          key: ValueKey(_remainingChanges),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _button(
                        text: _loading
                            ? (_importStatus.isNotEmpty
                                ? _importStatus
                                : 'importing...')
                            : 'Import Words',
                        onTap: _importWords,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= WORD LIST =================
                _section(
                  title: 'Word List',
                  child: Column(
                    children: [
                      _button(
                        text: 'Export Current Words',
                        onTap: _exportWords,
                      ),
                      if (_hasCustomWords) ...[
                        const SizedBox(height: 10),
                        _button(
                          text: 'Revert to Original Word List',
                          onTap: _revertWords,
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= DICTIONARY API =================
                _section(
                  title: 'Dictionary API',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Imported words are automatically enriched using the free dictionary. Add a Merriam-Webster key for higher quality definitions and etymology.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('https://dictionaryapi.com'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text(
                          'get a free key at dictionaryapi.com',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _mwKeyController,
                        obscureText: _mwKeyObscured,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'paste Merriam-Webster API key',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey.shade800),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mwKeyObscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _mwKeyObscured = !_mwKeyObscured),
                          ),
                        ),
                        onChanged: (_) => setState(() => _mwKeyValid = null),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _verifyingKey ? null : _saveMWKey,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _mwKeyValid == true
                                        ? Colors.green.shade700
                                        : _mwKeyValid == false
                                            ? Colors.red.shade700
                                            : Colors.grey.shade800,
                                  ),
                                ),
                                child: Center(
                                  child: _verifyingKey
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 1.5,
                                          ),
                                        )
                                      : Text(
                                          _mwKeyValid == true
                                              ? 'key saved ✓'
                                              : _mwKeyValid == false
                                                  ? 'invalid key'
                                                  : 'save & verify',
                                          style: TextStyle(
                                            color: _mwKeyValid == true
                                                ? Colors.green.shade400
                                                : _mwKeyValid == false
                                                    ? Colors.red.shade400
                                                    : Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          if (_mwKeyValid == true) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () async {
                                _mwKeyController.clear();
                                await SettingsService.setMWApiKey('');
                                if (!mounted) return;
                                setState(() => _mwKeyValid = null);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade800),
                                ),
                                child: const Text(
                                  'remove',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_mwKeyValid == null && _mwKeyController.text.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'using free dictionary — works without a key',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= LANGUAGE =================
                _section(
                  title: 'Language',
                  child: Column(
                    children: [
                      _langOption(label: 'English', tag: 'EN', enabled: true),
                      const SizedBox(height: 10),
                      _langOption(label: 'Japanese', tag: 'JP', enabled: false),
                      const SizedBox(height: 10),
                      _langOption(label: 'Arabic', tag: 'AR', enabled: false),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= NOTIFICATIONS =================
                _section(
                  title: 'Notifications',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily reminder at 8:00 AM',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.grey.shade700,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.shade900,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= RESET =================
                _section(
                  title: 'Reset',
                  child: Column(
                    children: [
                      _button(
                        text: _loading ? 'processing...' : 'Reset App (Progress Reset)',
                        onTap: _resetProgress,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}