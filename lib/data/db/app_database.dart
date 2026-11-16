import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Job states, stored by name.
enum JobStatus { queued, running, done, failed, canceled }

/// One download: what was asked for, and how it went.
@DataClassName('DownloadJob')
class DownloadJobs extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get itemId => text().nullable()();
  TextColumn get thumbnail => text().nullable()();
  TextColumn get site => text().nullable()();

  /// DownloadMode name.
  TextColumn get mode => text()();
  IntColumn get maxHeight => integer().nullable()();
  TextColumn get container => text().withDefault(const Constant('mp4'))();
  TextColumn get audioFormat => text().withDefault(const Constant('mp3'))();

  /// Comma-separated yt-dlp language codes; empty = no subtitles.
  TextColumn get subLangs => text().withDefault(const Constant(''))();
  BoolColumn get subAuto => boolean().withDefault(const Constant(false))();
  BoolColumn get subEmbed => boolean().withDefault(const Constant(false))();

  IntColumn get estimatedBytes => integer().nullable()();
  TextColumn get status => textEnum<JobStatus>()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get eta => integer().nullable()();

  /// Newline-separated output files.
  TextColumn get paths => text().withDefault(const Constant(''))();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [DownloadJobs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'grab'));

  @override
  int get schemaVersion => 1;
}
