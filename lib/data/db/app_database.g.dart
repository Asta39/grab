// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DownloadJobsTable extends DownloadJobs
    with TableInfo<$DownloadJobsTable, DownloadJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteMeta = const VerificationMeta('site');
  @override
  late final GeneratedColumn<String> site = GeneratedColumn<String>(
    'site',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxHeightMeta = const VerificationMeta(
    'maxHeight',
  );
  @override
  late final GeneratedColumn<int> maxHeight = GeneratedColumn<int>(
    'max_height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerMeta = const VerificationMeta(
    'container',
  );
  @override
  late final GeneratedColumn<String> container = GeneratedColumn<String>(
    'container',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mp4'),
  );
  static const VerificationMeta _audioFormatMeta = const VerificationMeta(
    'audioFormat',
  );
  @override
  late final GeneratedColumn<String> audioFormat = GeneratedColumn<String>(
    'audio_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mp3'),
  );
  static const VerificationMeta _subLangsMeta = const VerificationMeta(
    'subLangs',
  );
  @override
  late final GeneratedColumn<String> subLangs = GeneratedColumn<String>(
    'sub_langs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _subAutoMeta = const VerificationMeta(
    'subAuto',
  );
  @override
  late final GeneratedColumn<bool> subAuto = GeneratedColumn<bool>(
    'sub_auto',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sub_auto" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _subEmbedMeta = const VerificationMeta(
    'subEmbed',
  );
  @override
  late final GeneratedColumn<bool> subEmbed = GeneratedColumn<bool>(
    'sub_embed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sub_embed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _estimatedBytesMeta = const VerificationMeta(
    'estimatedBytes',
  );
  @override
  late final GeneratedColumn<int> estimatedBytes = GeneratedColumn<int>(
    'estimated_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<JobStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<JobStatus>($DownloadJobsTable.$converterstatus);
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _etaMeta = const VerificationMeta('eta');
  @override
  late final GeneratedColumn<int> eta = GeneratedColumn<int>(
    'eta',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pathsMeta = const VerificationMeta('paths');
  @override
  late final GeneratedColumn<String> paths = GeneratedColumn<String>(
    'paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    title,
    itemId,
    thumbnail,
    site,
    mode,
    maxHeight,
    container,
    audioFormat,
    subLangs,
    subAuto,
    subEmbed,
    estimatedBytes,
    status,
    progress,
    eta,
    paths,
    error,
    createdAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    }
    if (data.containsKey('site')) {
      context.handle(
        _siteMeta,
        site.isAcceptableOrUnknown(data['site']!, _siteMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('max_height')) {
      context.handle(
        _maxHeightMeta,
        maxHeight.isAcceptableOrUnknown(data['max_height']!, _maxHeightMeta),
      );
    }
    if (data.containsKey('container')) {
      context.handle(
        _containerMeta,
        container.isAcceptableOrUnknown(data['container']!, _containerMeta),
      );
    }
    if (data.containsKey('audio_format')) {
      context.handle(
        _audioFormatMeta,
        audioFormat.isAcceptableOrUnknown(
          data['audio_format']!,
          _audioFormatMeta,
        ),
      );
    }
    if (data.containsKey('sub_langs')) {
      context.handle(
        _subLangsMeta,
        subLangs.isAcceptableOrUnknown(data['sub_langs']!, _subLangsMeta),
      );
    }
    if (data.containsKey('sub_auto')) {
      context.handle(
        _subAutoMeta,
        subAuto.isAcceptableOrUnknown(data['sub_auto']!, _subAutoMeta),
      );
    }
    if (data.containsKey('sub_embed')) {
      context.handle(
        _subEmbedMeta,
        subEmbed.isAcceptableOrUnknown(data['sub_embed']!, _subEmbedMeta),
      );
    }
    if (data.containsKey('estimated_bytes')) {
      context.handle(
        _estimatedBytesMeta,
        estimatedBytes.isAcceptableOrUnknown(
          data['estimated_bytes']!,
          _estimatedBytesMeta,
        ),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('eta')) {
      context.handle(
        _etaMeta,
        eta.isAcceptableOrUnknown(data['eta']!, _etaMeta),
      );
    }
    if (data.containsKey('paths')) {
      context.handle(
        _pathsMeta,
        paths.isAcceptableOrUnknown(data['paths']!, _pathsMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail'],
      ),
      site: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      maxHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_height'],
      ),
      container: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container'],
      )!,
      audioFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_format'],
      )!,
      subLangs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_langs'],
      )!,
      subAuto: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sub_auto'],
      )!,
      subEmbed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sub_embed'],
      )!,
      estimatedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_bytes'],
      ),
      status: $DownloadJobsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      eta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}eta'],
      ),
      paths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paths'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $DownloadJobsTable createAlias(String alias) {
    return $DownloadJobsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<JobStatus, String, String> $converterstatus =
      const EnumNameConverter<JobStatus>(JobStatus.values);
}

class DownloadJob extends DataClass implements Insertable<DownloadJob> {
  final String id;
  final String url;
  final String title;
  final String? itemId;
  final String? thumbnail;
  final String? site;

  /// DownloadMode name.
  final String mode;
  final int? maxHeight;
  final String container;
  final String audioFormat;

  /// Comma-separated yt-dlp language codes; empty = no subtitles.
  final String subLangs;
  final bool subAuto;
  final bool subEmbed;
  final int? estimatedBytes;
  final JobStatus status;
  final double progress;
  final int? eta;

  /// Newline-separated output files.
  final String paths;
  final String? error;
  final DateTime createdAt;
  final DateTime? finishedAt;
  const DownloadJob({
    required this.id,
    required this.url,
    required this.title,
    this.itemId,
    this.thumbnail,
    this.site,
    required this.mode,
    this.maxHeight,
    required this.container,
    required this.audioFormat,
    required this.subLangs,
    required this.subAuto,
    required this.subEmbed,
    this.estimatedBytes,
    required this.status,
    required this.progress,
    this.eta,
    required this.paths,
    this.error,
    required this.createdAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<String>(thumbnail);
    }
    if (!nullToAbsent || site != null) {
      map['site'] = Variable<String>(site);
    }
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || maxHeight != null) {
      map['max_height'] = Variable<int>(maxHeight);
    }
    map['container'] = Variable<String>(container);
    map['audio_format'] = Variable<String>(audioFormat);
    map['sub_langs'] = Variable<String>(subLangs);
    map['sub_auto'] = Variable<bool>(subAuto);
    map['sub_embed'] = Variable<bool>(subEmbed);
    if (!nullToAbsent || estimatedBytes != null) {
      map['estimated_bytes'] = Variable<int>(estimatedBytes);
    }
    {
      map['status'] = Variable<String>(
        $DownloadJobsTable.$converterstatus.toSql(status),
      );
    }
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || eta != null) {
      map['eta'] = Variable<int>(eta);
    }
    map['paths'] = Variable<String>(paths);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  DownloadJobsCompanion toCompanion(bool nullToAbsent) {
    return DownloadJobsCompanion(
      id: Value(id),
      url: Value(url),
      title: Value(title),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
      site: site == null && nullToAbsent ? const Value.absent() : Value(site),
      mode: Value(mode),
      maxHeight: maxHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHeight),
      container: Value(container),
      audioFormat: Value(audioFormat),
      subLangs: Value(subLangs),
      subAuto: Value(subAuto),
      subEmbed: Value(subEmbed),
      estimatedBytes: estimatedBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedBytes),
      status: Value(status),
      progress: Value(progress),
      eta: eta == null && nullToAbsent ? const Value.absent() : Value(eta),
      paths: Value(paths),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      createdAt: Value(createdAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory DownloadJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadJob(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String>(json['title']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      thumbnail: serializer.fromJson<String?>(json['thumbnail']),
      site: serializer.fromJson<String?>(json['site']),
      mode: serializer.fromJson<String>(json['mode']),
      maxHeight: serializer.fromJson<int?>(json['maxHeight']),
      container: serializer.fromJson<String>(json['container']),
      audioFormat: serializer.fromJson<String>(json['audioFormat']),
      subLangs: serializer.fromJson<String>(json['subLangs']),
      subAuto: serializer.fromJson<bool>(json['subAuto']),
      subEmbed: serializer.fromJson<bool>(json['subEmbed']),
      estimatedBytes: serializer.fromJson<int?>(json['estimatedBytes']),
      status: $DownloadJobsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      progress: serializer.fromJson<double>(json['progress']),
      eta: serializer.fromJson<int?>(json['eta']),
      paths: serializer.fromJson<String>(json['paths']),
      error: serializer.fromJson<String?>(json['error']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String>(title),
      'itemId': serializer.toJson<String?>(itemId),
      'thumbnail': serializer.toJson<String?>(thumbnail),
      'site': serializer.toJson<String?>(site),
      'mode': serializer.toJson<String>(mode),
      'maxHeight': serializer.toJson<int?>(maxHeight),
      'container': serializer.toJson<String>(container),
      'audioFormat': serializer.toJson<String>(audioFormat),
      'subLangs': serializer.toJson<String>(subLangs),
      'subAuto': serializer.toJson<bool>(subAuto),
      'subEmbed': serializer.toJson<bool>(subEmbed),
      'estimatedBytes': serializer.toJson<int?>(estimatedBytes),
      'status': serializer.toJson<String>(
        $DownloadJobsTable.$converterstatus.toJson(status),
      ),
      'progress': serializer.toJson<double>(progress),
      'eta': serializer.toJson<int?>(eta),
      'paths': serializer.toJson<String>(paths),
      'error': serializer.toJson<String?>(error),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  DownloadJob copyWith({
    String? id,
    String? url,
    String? title,
    Value<String?> itemId = const Value.absent(),
    Value<String?> thumbnail = const Value.absent(),
    Value<String?> site = const Value.absent(),
    String? mode,
    Value<int?> maxHeight = const Value.absent(),
    String? container,
    String? audioFormat,
    String? subLangs,
    bool? subAuto,
    bool? subEmbed,
    Value<int?> estimatedBytes = const Value.absent(),
    JobStatus? status,
    double? progress,
    Value<int?> eta = const Value.absent(),
    String? paths,
    Value<String?> error = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => DownloadJob(
    id: id ?? this.id,
    url: url ?? this.url,
    title: title ?? this.title,
    itemId: itemId.present ? itemId.value : this.itemId,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    site: site.present ? site.value : this.site,
    mode: mode ?? this.mode,
    maxHeight: maxHeight.present ? maxHeight.value : this.maxHeight,
    container: container ?? this.container,
    audioFormat: audioFormat ?? this.audioFormat,
    subLangs: subLangs ?? this.subLangs,
    subAuto: subAuto ?? this.subAuto,
    subEmbed: subEmbed ?? this.subEmbed,
    estimatedBytes: estimatedBytes.present
        ? estimatedBytes.value
        : this.estimatedBytes,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    eta: eta.present ? eta.value : this.eta,
    paths: paths ?? this.paths,
    error: error.present ? error.value : this.error,
    createdAt: createdAt ?? this.createdAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  DownloadJob copyWithCompanion(DownloadJobsCompanion data) {
    return DownloadJob(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      site: data.site.present ? data.site.value : this.site,
      mode: data.mode.present ? data.mode.value : this.mode,
      maxHeight: data.maxHeight.present ? data.maxHeight.value : this.maxHeight,
      container: data.container.present ? data.container.value : this.container,
      audioFormat: data.audioFormat.present
          ? data.audioFormat.value
          : this.audioFormat,
      subLangs: data.subLangs.present ? data.subLangs.value : this.subLangs,
      subAuto: data.subAuto.present ? data.subAuto.value : this.subAuto,
      subEmbed: data.subEmbed.present ? data.subEmbed.value : this.subEmbed,
      estimatedBytes: data.estimatedBytes.present
          ? data.estimatedBytes.value
          : this.estimatedBytes,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      eta: data.eta.present ? data.eta.value : this.eta,
      paths: data.paths.present ? data.paths.value : this.paths,
      error: data.error.present ? data.error.value : this.error,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJob(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('itemId: $itemId, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('site: $site, ')
          ..write('mode: $mode, ')
          ..write('maxHeight: $maxHeight, ')
          ..write('container: $container, ')
          ..write('audioFormat: $audioFormat, ')
          ..write('subLangs: $subLangs, ')
          ..write('subAuto: $subAuto, ')
          ..write('subEmbed: $subEmbed, ')
          ..write('estimatedBytes: $estimatedBytes, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('eta: $eta, ')
          ..write('paths: $paths, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    url,
    title,
    itemId,
    thumbnail,
    site,
    mode,
    maxHeight,
    container,
    audioFormat,
    subLangs,
    subAuto,
    subEmbed,
    estimatedBytes,
    status,
    progress,
    eta,
    paths,
    error,
    createdAt,
    finishedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadJob &&
          other.id == this.id &&
          other.url == this.url &&
          other.title == this.title &&
          other.itemId == this.itemId &&
          other.thumbnail == this.thumbnail &&
          other.site == this.site &&
          other.mode == this.mode &&
          other.maxHeight == this.maxHeight &&
          other.container == this.container &&
          other.audioFormat == this.audioFormat &&
          other.subLangs == this.subLangs &&
          other.subAuto == this.subAuto &&
          other.subEmbed == this.subEmbed &&
          other.estimatedBytes == this.estimatedBytes &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.eta == this.eta &&
          other.paths == this.paths &&
          other.error == this.error &&
          other.createdAt == this.createdAt &&
          other.finishedAt == this.finishedAt);
}

class DownloadJobsCompanion extends UpdateCompanion<DownloadJob> {
  final Value<String> id;
  final Value<String> url;
  final Value<String> title;
  final Value<String?> itemId;
  final Value<String?> thumbnail;
  final Value<String?> site;
  final Value<String> mode;
  final Value<int?> maxHeight;
  final Value<String> container;
  final Value<String> audioFormat;
  final Value<String> subLangs;
  final Value<bool> subAuto;
  final Value<bool> subEmbed;
  final Value<int?> estimatedBytes;
  final Value<JobStatus> status;
  final Value<double> progress;
  final Value<int?> eta;
  final Value<String> paths;
  final Value<String?> error;
  final Value<DateTime> createdAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const DownloadJobsCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.itemId = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.site = const Value.absent(),
    this.mode = const Value.absent(),
    this.maxHeight = const Value.absent(),
    this.container = const Value.absent(),
    this.audioFormat = const Value.absent(),
    this.subLangs = const Value.absent(),
    this.subAuto = const Value.absent(),
    this.subEmbed = const Value.absent(),
    this.estimatedBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.eta = const Value.absent(),
    this.paths = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadJobsCompanion.insert({
    required String id,
    required String url,
    required String title,
    this.itemId = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.site = const Value.absent(),
    required String mode,
    this.maxHeight = const Value.absent(),
    this.container = const Value.absent(),
    this.audioFormat = const Value.absent(),
    this.subLangs = const Value.absent(),
    this.subAuto = const Value.absent(),
    this.subEmbed = const Value.absent(),
    this.estimatedBytes = const Value.absent(),
    required JobStatus status,
    this.progress = const Value.absent(),
    this.eta = const Value.absent(),
    this.paths = const Value.absent(),
    this.error = const Value.absent(),
    required DateTime createdAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       url = Value(url),
       title = Value(title),
       mode = Value(mode),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<DownloadJob> custom({
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? itemId,
    Expression<String>? thumbnail,
    Expression<String>? site,
    Expression<String>? mode,
    Expression<int>? maxHeight,
    Expression<String>? container,
    Expression<String>? audioFormat,
    Expression<String>? subLangs,
    Expression<bool>? subAuto,
    Expression<bool>? subEmbed,
    Expression<int>? estimatedBytes,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? eta,
    Expression<String>? paths,
    Expression<String>? error,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (itemId != null) 'item_id': itemId,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (site != null) 'site': site,
      if (mode != null) 'mode': mode,
      if (maxHeight != null) 'max_height': maxHeight,
      if (container != null) 'container': container,
      if (audioFormat != null) 'audio_format': audioFormat,
      if (subLangs != null) 'sub_langs': subLangs,
      if (subAuto != null) 'sub_auto': subAuto,
      if (subEmbed != null) 'sub_embed': subEmbed,
      if (estimatedBytes != null) 'estimated_bytes': estimatedBytes,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (eta != null) 'eta': eta,
      if (paths != null) 'paths': paths,
      if (error != null) 'error': error,
      if (createdAt != null) 'created_at': createdAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? url,
    Value<String>? title,
    Value<String?>? itemId,
    Value<String?>? thumbnail,
    Value<String?>? site,
    Value<String>? mode,
    Value<int?>? maxHeight,
    Value<String>? container,
    Value<String>? audioFormat,
    Value<String>? subLangs,
    Value<bool>? subAuto,
    Value<bool>? subEmbed,
    Value<int?>? estimatedBytes,
    Value<JobStatus>? status,
    Value<double>? progress,
    Value<int?>? eta,
    Value<String>? paths,
    Value<String?>? error,
    Value<DateTime>? createdAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return DownloadJobsCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      itemId: itemId ?? this.itemId,
      thumbnail: thumbnail ?? this.thumbnail,
      site: site ?? this.site,
      mode: mode ?? this.mode,
      maxHeight: maxHeight ?? this.maxHeight,
      container: container ?? this.container,
      audioFormat: audioFormat ?? this.audioFormat,
      subLangs: subLangs ?? this.subLangs,
      subAuto: subAuto ?? this.subAuto,
      subEmbed: subEmbed ?? this.subEmbed,
      estimatedBytes: estimatedBytes ?? this.estimatedBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      eta: eta ?? this.eta,
      paths: paths ?? this.paths,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (site.present) {
      map['site'] = Variable<String>(site.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (maxHeight.present) {
      map['max_height'] = Variable<int>(maxHeight.value);
    }
    if (container.present) {
      map['container'] = Variable<String>(container.value);
    }
    if (audioFormat.present) {
      map['audio_format'] = Variable<String>(audioFormat.value);
    }
    if (subLangs.present) {
      map['sub_langs'] = Variable<String>(subLangs.value);
    }
    if (subAuto.present) {
      map['sub_auto'] = Variable<bool>(subAuto.value);
    }
    if (subEmbed.present) {
      map['sub_embed'] = Variable<bool>(subEmbed.value);
    }
    if (estimatedBytes.present) {
      map['estimated_bytes'] = Variable<int>(estimatedBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $DownloadJobsTable.$converterstatus.toSql(status.value),
      );
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (eta.present) {
      map['eta'] = Variable<int>(eta.value);
    }
    if (paths.present) {
      map['paths'] = Variable<String>(paths.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJobsCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('itemId: $itemId, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('site: $site, ')
          ..write('mode: $mode, ')
          ..write('maxHeight: $maxHeight, ')
          ..write('container: $container, ')
          ..write('audioFormat: $audioFormat, ')
          ..write('subLangs: $subLangs, ')
          ..write('subAuto: $subAuto, ')
          ..write('subEmbed: $subEmbed, ')
          ..write('estimatedBytes: $estimatedBytes, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('eta: $eta, ')
          ..write('paths: $paths, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DownloadJobsTable downloadJobs = $DownloadJobsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [downloadJobs];
}

typedef $$DownloadJobsTableCreateCompanionBuilder =
    DownloadJobsCompanion Function({
      required String id,
      required String url,
      required String title,
      Value<String?> itemId,
      Value<String?> thumbnail,
      Value<String?> site,
      required String mode,
      Value<int?> maxHeight,
      Value<String> container,
      Value<String> audioFormat,
      Value<String> subLangs,
      Value<bool> subAuto,
      Value<bool> subEmbed,
      Value<int?> estimatedBytes,
      required JobStatus status,
      Value<double> progress,
      Value<int?> eta,
      Value<String> paths,
      Value<String?> error,
      required DateTime createdAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$DownloadJobsTableUpdateCompanionBuilder =
    DownloadJobsCompanion Function({
      Value<String> id,
      Value<String> url,
      Value<String> title,
      Value<String?> itemId,
      Value<String?> thumbnail,
      Value<String?> site,
      Value<String> mode,
      Value<int?> maxHeight,
      Value<String> container,
      Value<String> audioFormat,
      Value<String> subLangs,
      Value<bool> subAuto,
      Value<bool> subEmbed,
      Value<int?> estimatedBytes,
      Value<JobStatus> status,
      Value<double> progress,
      Value<int?> eta,
      Value<String> paths,
      Value<String?> error,
      Value<DateTime> createdAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

class $$DownloadJobsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get site => $composableBuilder(
    column: $table.site,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHeight => $composableBuilder(
    column: $table.maxHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get container => $composableBuilder(
    column: $table.container,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioFormat => $composableBuilder(
    column: $table.audioFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subLangs => $composableBuilder(
    column: $table.subLangs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get subAuto => $composableBuilder(
    column: $table.subAuto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get subEmbed => $composableBuilder(
    column: $table.subEmbed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedBytes => $composableBuilder(
    column: $table.estimatedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<JobStatus, JobStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eta => $composableBuilder(
    column: $table.eta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paths => $composableBuilder(
    column: $table.paths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get site => $composableBuilder(
    column: $table.site,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHeight => $composableBuilder(
    column: $table.maxHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get container => $composableBuilder(
    column: $table.container,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioFormat => $composableBuilder(
    column: $table.audioFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subLangs => $composableBuilder(
    column: $table.subLangs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get subAuto => $composableBuilder(
    column: $table.subAuto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get subEmbed => $composableBuilder(
    column: $table.subEmbed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedBytes => $composableBuilder(
    column: $table.estimatedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eta => $composableBuilder(
    column: $table.eta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paths => $composableBuilder(
    column: $table.paths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<String> get site =>
      $composableBuilder(column: $table.site, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get maxHeight =>
      $composableBuilder(column: $table.maxHeight, builder: (column) => column);

  GeneratedColumn<String> get container =>
      $composableBuilder(column: $table.container, builder: (column) => column);

  GeneratedColumn<String> get audioFormat => $composableBuilder(
    column: $table.audioFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subLangs =>
      $composableBuilder(column: $table.subLangs, builder: (column) => column);

  GeneratedColumn<bool> get subAuto =>
      $composableBuilder(column: $table.subAuto, builder: (column) => column);

  GeneratedColumn<bool> get subEmbed =>
      $composableBuilder(column: $table.subEmbed, builder: (column) => column);

  GeneratedColumn<int> get estimatedBytes => $composableBuilder(
    column: $table.estimatedBytes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<JobStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get eta =>
      $composableBuilder(column: $table.eta, builder: (column) => column);

  GeneratedColumn<String> get paths =>
      $composableBuilder(column: $table.paths, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$DownloadJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadJobsTable,
          DownloadJob,
          $$DownloadJobsTableFilterComposer,
          $$DownloadJobsTableOrderingComposer,
          $$DownloadJobsTableAnnotationComposer,
          $$DownloadJobsTableCreateCompanionBuilder,
          $$DownloadJobsTableUpdateCompanionBuilder,
          (
            DownloadJob,
            BaseReferences<_$AppDatabase, $DownloadJobsTable, DownloadJob>,
          ),
          DownloadJob,
          PrefetchHooks Function()
        > {
  $$DownloadJobsTableTableManager(_$AppDatabase db, $DownloadJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<String?> site = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int?> maxHeight = const Value.absent(),
                Value<String> container = const Value.absent(),
                Value<String> audioFormat = const Value.absent(),
                Value<String> subLangs = const Value.absent(),
                Value<bool> subAuto = const Value.absent(),
                Value<bool> subEmbed = const Value.absent(),
                Value<int?> estimatedBytes = const Value.absent(),
                Value<JobStatus> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int?> eta = const Value.absent(),
                Value<String> paths = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobsCompanion(
                id: id,
                url: url,
                title: title,
                itemId: itemId,
                thumbnail: thumbnail,
                site: site,
                mode: mode,
                maxHeight: maxHeight,
                container: container,
                audioFormat: audioFormat,
                subLangs: subLangs,
                subAuto: subAuto,
                subEmbed: subEmbed,
                estimatedBytes: estimatedBytes,
                status: status,
                progress: progress,
                eta: eta,
                paths: paths,
                error: error,
                createdAt: createdAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String url,
                required String title,
                Value<String?> itemId = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<String?> site = const Value.absent(),
                required String mode,
                Value<int?> maxHeight = const Value.absent(),
                Value<String> container = const Value.absent(),
                Value<String> audioFormat = const Value.absent(),
                Value<String> subLangs = const Value.absent(),
                Value<bool> subAuto = const Value.absent(),
                Value<bool> subEmbed = const Value.absent(),
                Value<int?> estimatedBytes = const Value.absent(),
                required JobStatus status,
                Value<double> progress = const Value.absent(),
                Value<int?> eta = const Value.absent(),
                Value<String> paths = const Value.absent(),
                Value<String?> error = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobsCompanion.insert(
                id: id,
                url: url,
                title: title,
                itemId: itemId,
                thumbnail: thumbnail,
                site: site,
                mode: mode,
                maxHeight: maxHeight,
                container: container,
                audioFormat: audioFormat,
                subLangs: subLangs,
                subAuto: subAuto,
                subEmbed: subEmbed,
                estimatedBytes: estimatedBytes,
                status: status,
                progress: progress,
                eta: eta,
                paths: paths,
                error: error,
                createdAt: createdAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadJobsTable, DownloadJob>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DownloadJobsTable,
                    DownloadJob
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadJobsTable,
      DownloadJob,
      $$DownloadJobsTableFilterComposer,
      $$DownloadJobsTableOrderingComposer,
      $$DownloadJobsTableAnnotationComposer,
      $$DownloadJobsTableCreateCompanionBuilder,
      $$DownloadJobsTableUpdateCompanionBuilder,
      (
        DownloadJob,
        BaseReferences<_$AppDatabase, $DownloadJobsTable, DownloadJob>,
      ),
      DownloadJob,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DownloadJobsTableTableManager get downloadJobs =>
      $$DownloadJobsTableTableManager(_db, _db.downloadJobs);
}
