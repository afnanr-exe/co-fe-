# co:fe

A vocabulary learning app built for people who actually want the words to stick.
No flashcard grind. No streaks for show. Just a word a day, a puzzle to test it, and a quiz that only unlocks when you've earned it.

Built by **Afnan Rahman** — [afnan061502@gmail.com](mailto:afnan061502@gmail.com)

---

## Download

- **Google Play** — coming soon
- **GitHub Releases** — [download APK](../../releases/latest)

---

## Features

### Word of the Day
A new word every day pulled from a 365-word curated list. Each entry includes the definition, part of speech, pronunciation, an example sentence, etymology, and a difficulty tier. The word shown today is the same one that will appear in the Daily Puzzle in 14 days — giving you time to actually learn it before you're tested.

A home screen widget displays the current word so you never have to open the app to see it.

### Daily Puzzle
A multiple-choice question built around the word of the day. Four options, one correct answer. You get one attempt per day — no replays. Use the hint to reveal the etymology if you're stuck, though it'll be marked as assisted. Get it wrong and the word is added to your missed list to come back in the quiz.

### Quiz
The quiz unlocks after you've missed 3 new words since the last quiz. It draws only from your personal missed words list — so everything in it is something you've already struggled with. Words you get right are removed from the list. Words you miss stay on it.

Scoring has two components:
- **Performance score** — accuracy weighted by word difficulty
- **Habit score** — tracks consistency over time, Duolingo-style decay if you skip days

The final score blends both. Results are archived monthly and yearly.

### Stats
A full breakdown of your progress:
- Current and best streak
- Overall accuracy
- Puzzle performance score
- Weekly activity calendar (Sunday–Saturday)
- Habit score with decay indicator
- Quiz history with missed and mastered word lists
- Mistakes needed until the next quiz unlocks

### Notifications
Optional daily reminder at 8:00 AM. Toggle it on or off in Settings — off by default.

### Settings
- Import a custom word list (up to 365 words, comma or space separated) — limited to 3 changes per day
- Export your current word list
- Reset all progress (with confirmation)
- Language selector (English active — Japanese and Arabic coming soon)

---

## Tech

- Flutter (Dart)
- SharedPreferences for local persistence
- `flutter_local_notifications` for scheduled reminders
- `home_widget` for the Android home screen widget
- `timezone` for accurate daily notification scheduling

---

## Building

```bash
# Debug
flutter run

# Play Store
flutter build appbundle --release

# GitHub APK (split by architecture)
flutter build apk --release --split-per-abi
```

Signing requires `android/key.properties` — see `android/key.properties` for the expected format (not committed to version control).

---

## License

[Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](LICENSE)

Free to use, modify, and share — just don't sell it or make money from it. Credit appreciated.
