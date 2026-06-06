import 'package:isar_community/isar_community.dart';

part 'journal_entry.g.dart';

@collection
class JournalEntry {
  Id id = Isar.autoIncrement;
  late String entryId;
  late DateTime date;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String entryType; // 'morning' | 'evening' | 'free'
  late int moodRating;
  late int energyRating;
  late String moodEmoji;
  late String? gratitudePrompt;
  late String? intentionPrompt;
  late String? reflectionPrompt;
  late String? freeText;
  late List<String> tags;
  late bool isSynced;
}