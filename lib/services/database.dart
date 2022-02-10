import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get date => text()();
  BoolColumn get isSelected => boolean().withDefault(Constant(false))();
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
  Future<List<Note>> getNoteList() async {
    return await select(notes).get();
  }

  //INSERT NEW NOTE IN DB
  Future<int> insertNote(NotesCompanion noteCompanion) async {
    return await into(notes).insert(noteCompanion);
  }

  //DELETE FROM DATABASE
  Future<int> deleteNote(Note noteData) async {
    return await delete(notes).delete(noteData);
  }

  // UPDATE NOTES
  Future<bool> updateNote(Note noteData) async {
    return await update(notes).replace(noteData);
  }
}
