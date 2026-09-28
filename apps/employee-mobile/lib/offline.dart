import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
part 'offline.g.dart';

// No HR records, audio, tokens or pending writes are approved for offline use
// in Phase 1. Only non-sensitive UI preferences can be stored here.
class UiPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [UiPreferences])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase()
    : super(
        LazyDatabase(() async {
          final directory = await getApplicationSupportDirectory();
          return NativeDatabase.createInBackground(
            File(p.join(directory.path, 'ui_preferences.sqlite')),
          );
        }),
      );
  @override
  int get schemaVersion => 1;
}
