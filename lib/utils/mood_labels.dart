import '../l10n/app_localizations.dart';
import '../models/mood_entry.dart';

const Map<MoodLevel, String> moodEmojis = {
  MoodLevel.happy: '\u{1F642}', // 🙂
  MoodLevel.excited: '\u{1F929}', // 🤩
  MoodLevel.grateful: '\u{1F64F}', // 🙏
  MoodLevel.relaxed: '\u{1F60C}', // 😌
  MoodLevel.content: '\u{1F60A}', // 😊
  MoodLevel.tired: '\u{1F634}', // 😴
  MoodLevel.unsure: '\u{1F914}', // 🤔
  MoodLevel.bored: '\u{1F610}', // 😐
  MoodLevel.anxious: '\u{1F61F}', // 😟
  MoodLevel.angry: '\u{1F620}', // 😠
  MoodLevel.stressed: '\u{1F623}', // 😣
  MoodLevel.sad: '\u{1F622}', // 😢
};

String moodLabel(MoodLevel level, AppLocalizations strings) {
  switch (level) {
    case MoodLevel.happy:
      return strings.t('mood.option.happy');
    case MoodLevel.excited:
      return strings.t('mood.option.excited');
    case MoodLevel.grateful:
      return strings.t('mood.option.grateful');
    case MoodLevel.relaxed:
      return strings.t('mood.option.relaxed');
    case MoodLevel.content:
      return strings.t('mood.option.content');
    case MoodLevel.tired:
      return strings.t('mood.option.tired');
    case MoodLevel.unsure:
      return strings.t('mood.option.unsure');
    case MoodLevel.bored:
      return strings.t('mood.option.bored');
    case MoodLevel.anxious:
      return strings.t('mood.option.anxious');
    case MoodLevel.angry:
      return strings.t('mood.option.angry');
    case MoodLevel.stressed:
      return strings.t('mood.option.stressed');
    case MoodLevel.sad:
      return strings.t('mood.option.sad');
  }
}
