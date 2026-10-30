// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_database.dart';

// ignore_for_file: type=lint
class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
    'song_id',
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
  static const VerificationMeta _artistNameMeta = const VerificationMeta(
    'artistName',
  );
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
    'artist_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreIdMeta = const VerificationMeta(
    'genreId',
  );
  @override
  late final GeneratedColumn<int> genreId = GeneratedColumn<int>(
    'genre_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverLargeUrlMeta = const VerificationMeta(
    'coverLargeUrl',
  );
  @override
  late final GeneratedColumn<String> coverLargeUrl = GeneratedColumn<String>(
    'cover_large_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedSha256Meta = const VerificationMeta(
    'expectedSha256',
  );
  @override
  late final GeneratedColumn<String> expectedSha256 = GeneratedColumn<String>(
    'expected_sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadRowState, int> state =
      GeneratedColumn<int>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DownloadRowState>($DownloadsTable.$converterstate);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioFileMeta = const VerificationMeta(
    'audioFile',
  );
  @override
  late final GeneratedColumn<String> audioFile = GeneratedColumn<String>(
    'audio_file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverFileMeta = const VerificationMeta(
    'coverFile',
  );
  @override
  late final GeneratedColumn<String> coverFile = GeneratedColumn<String>(
    'cover_file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    songId,
    title,
    artistName,
    genreId,
    description,
    durationMs,
    audioUrl,
    coverUrl,
    coverLargeUrl,
    expectedSha256,
    state,
    taskId,
    audioFile,
    coverFile,
    contentType,
    sizeBytes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<Download> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
        _artistNameMeta,
        artistName.isAcceptableOrUnknown(data['artist_name']!, _artistNameMeta),
      );
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('genre_id')) {
      context.handle(
        _genreIdMeta,
        genreId.isAcceptableOrUnknown(data['genre_id']!, _genreIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_audioUrlMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('cover_large_url')) {
      context.handle(
        _coverLargeUrlMeta,
        coverLargeUrl.isAcceptableOrUnknown(
          data['cover_large_url']!,
          _coverLargeUrlMeta,
        ),
      );
    }
    if (data.containsKey('expected_sha256')) {
      context.handle(
        _expectedSha256Meta,
        expectedSha256.isAcceptableOrUnknown(
          data['expected_sha256']!,
          _expectedSha256Meta,
        ),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('audio_file')) {
      context.handle(
        _audioFileMeta,
        audioFile.isAcceptableOrUnknown(data['audio_file']!, _audioFileMeta),
      );
    }
    if (data.containsKey('cover_file')) {
      context.handle(
        _coverFileMeta,
        coverFile.isAcceptableOrUnknown(data['cover_file']!, _coverFileMeta),
      );
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artistName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_name'],
      )!,
      genreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}genre_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      coverLargeUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_large_url'],
      ),
      expectedSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_sha256'],
      ),
      state: $DownloadsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}state'],
        )!,
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      audioFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_file'],
      ),
      coverFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_file'],
      ),
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DownloadRowState, int, int> $converterstate =
      const EnumIndexConverter<DownloadRowState>(DownloadRowState.values);
}

class Download extends DataClass implements Insertable<Download> {
  final String songId;
  final String title;
  final String artistName;
  final int? genreId;

  /// Se muestra bajo el título también sin red (v2).
  final String? description;
  final int durationMs;
  final String audioUrl;
  final String? coverUrl;
  final String? coverLargeUrl;

  /// SHA-256 esperado según el catálogo; si no coincide, la descarga falla.
  final String? expectedSha256;
  final DownloadRowState state;
  final String taskId;
  final String? audioFile;
  final String? coverFile;
  final String? contentType;

  /// Bytes que ocupa en disco (audio cifrado + portada).
  final int? sizeBytes;
  final DateTime createdAt;
  const Download({
    required this.songId,
    required this.title,
    required this.artistName,
    this.genreId,
    this.description,
    required this.durationMs,
    required this.audioUrl,
    this.coverUrl,
    this.coverLargeUrl,
    this.expectedSha256,
    required this.state,
    required this.taskId,
    this.audioFile,
    this.coverFile,
    this.contentType,
    this.sizeBytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<String>(songId);
    map['title'] = Variable<String>(title);
    map['artist_name'] = Variable<String>(artistName);
    if (!nullToAbsent || genreId != null) {
      map['genre_id'] = Variable<int>(genreId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['audio_url'] = Variable<String>(audioUrl);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || coverLargeUrl != null) {
      map['cover_large_url'] = Variable<String>(coverLargeUrl);
    }
    if (!nullToAbsent || expectedSha256 != null) {
      map['expected_sha256'] = Variable<String>(expectedSha256);
    }
    {
      map['state'] = Variable<int>(
        $DownloadsTable.$converterstate.toSql(state),
      );
    }
    map['task_id'] = Variable<String>(taskId);
    if (!nullToAbsent || audioFile != null) {
      map['audio_file'] = Variable<String>(audioFile);
    }
    if (!nullToAbsent || coverFile != null) {
      map['cover_file'] = Variable<String>(coverFile);
    }
    if (!nullToAbsent || contentType != null) {
      map['content_type'] = Variable<String>(contentType);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      songId: Value(songId),
      title: Value(title),
      artistName: Value(artistName),
      genreId: genreId == null && nullToAbsent
          ? const Value.absent()
          : Value(genreId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      durationMs: Value(durationMs),
      audioUrl: Value(audioUrl),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      coverLargeUrl: coverLargeUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverLargeUrl),
      expectedSha256: expectedSha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedSha256),
      state: Value(state),
      taskId: Value(taskId),
      audioFile: audioFile == null && nullToAbsent
          ? const Value.absent()
          : Value(audioFile),
      coverFile: coverFile == null && nullToAbsent
          ? const Value.absent()
          : Value(coverFile),
      contentType: contentType == null && nullToAbsent
          ? const Value.absent()
          : Value(contentType),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      createdAt: Value(createdAt),
    );
  }

  factory Download.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      songId: serializer.fromJson<String>(json['songId']),
      title: serializer.fromJson<String>(json['title']),
      artistName: serializer.fromJson<String>(json['artistName']),
      genreId: serializer.fromJson<int?>(json['genreId']),
      description: serializer.fromJson<String?>(json['description']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      audioUrl: serializer.fromJson<String>(json['audioUrl']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      coverLargeUrl: serializer.fromJson<String?>(json['coverLargeUrl']),
      expectedSha256: serializer.fromJson<String?>(json['expectedSha256']),
      state: $DownloadsTable.$converterstate.fromJson(
        serializer.fromJson<int>(json['state']),
      ),
      taskId: serializer.fromJson<String>(json['taskId']),
      audioFile: serializer.fromJson<String?>(json['audioFile']),
      coverFile: serializer.fromJson<String?>(json['coverFile']),
      contentType: serializer.fromJson<String?>(json['contentType']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<String>(songId),
      'title': serializer.toJson<String>(title),
      'artistName': serializer.toJson<String>(artistName),
      'genreId': serializer.toJson<int?>(genreId),
      'description': serializer.toJson<String?>(description),
      'durationMs': serializer.toJson<int>(durationMs),
      'audioUrl': serializer.toJson<String>(audioUrl),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'coverLargeUrl': serializer.toJson<String?>(coverLargeUrl),
      'expectedSha256': serializer.toJson<String?>(expectedSha256),
      'state': serializer.toJson<int>(
        $DownloadsTable.$converterstate.toJson(state),
      ),
      'taskId': serializer.toJson<String>(taskId),
      'audioFile': serializer.toJson<String?>(audioFile),
      'coverFile': serializer.toJson<String?>(coverFile),
      'contentType': serializer.toJson<String?>(contentType),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Download copyWith({
    String? songId,
    String? title,
    String? artistName,
    Value<int?> genreId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? durationMs,
    String? audioUrl,
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> coverLargeUrl = const Value.absent(),
    Value<String?> expectedSha256 = const Value.absent(),
    DownloadRowState? state,
    String? taskId,
    Value<String?> audioFile = const Value.absent(),
    Value<String?> coverFile = const Value.absent(),
    Value<String?> contentType = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    DateTime? createdAt,
  }) => Download(
    songId: songId ?? this.songId,
    title: title ?? this.title,
    artistName: artistName ?? this.artistName,
    genreId: genreId.present ? genreId.value : this.genreId,
    description: description.present ? description.value : this.description,
    durationMs: durationMs ?? this.durationMs,
    audioUrl: audioUrl ?? this.audioUrl,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    coverLargeUrl: coverLargeUrl.present
        ? coverLargeUrl.value
        : this.coverLargeUrl,
    expectedSha256: expectedSha256.present
        ? expectedSha256.value
        : this.expectedSha256,
    state: state ?? this.state,
    taskId: taskId ?? this.taskId,
    audioFile: audioFile.present ? audioFile.value : this.audioFile,
    coverFile: coverFile.present ? coverFile.value : this.coverFile,
    contentType: contentType.present ? contentType.value : this.contentType,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
  );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      songId: data.songId.present ? data.songId.value : this.songId,
      title: data.title.present ? data.title.value : this.title,
      artistName: data.artistName.present
          ? data.artistName.value
          : this.artistName,
      genreId: data.genreId.present ? data.genreId.value : this.genreId,
      description: data.description.present
          ? data.description.value
          : this.description,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      coverLargeUrl: data.coverLargeUrl.present
          ? data.coverLargeUrl.value
          : this.coverLargeUrl,
      expectedSha256: data.expectedSha256.present
          ? data.expectedSha256.value
          : this.expectedSha256,
      state: data.state.present ? data.state.value : this.state,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      audioFile: data.audioFile.present ? data.audioFile.value : this.audioFile,
      coverFile: data.coverFile.present ? data.coverFile.value : this.coverFile,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('songId: $songId, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('genreId: $genreId, ')
          ..write('description: $description, ')
          ..write('durationMs: $durationMs, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverLargeUrl: $coverLargeUrl, ')
          ..write('expectedSha256: $expectedSha256, ')
          ..write('state: $state, ')
          ..write('taskId: $taskId, ')
          ..write('audioFile: $audioFile, ')
          ..write('coverFile: $coverFile, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    songId,
    title,
    artistName,
    genreId,
    description,
    durationMs,
    audioUrl,
    coverUrl,
    coverLargeUrl,
    expectedSha256,
    state,
    taskId,
    audioFile,
    coverFile,
    contentType,
    sizeBytes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.songId == this.songId &&
          other.title == this.title &&
          other.artistName == this.artistName &&
          other.genreId == this.genreId &&
          other.description == this.description &&
          other.durationMs == this.durationMs &&
          other.audioUrl == this.audioUrl &&
          other.coverUrl == this.coverUrl &&
          other.coverLargeUrl == this.coverLargeUrl &&
          other.expectedSha256 == this.expectedSha256 &&
          other.state == this.state &&
          other.taskId == this.taskId &&
          other.audioFile == this.audioFile &&
          other.coverFile == this.coverFile &&
          other.contentType == this.contentType &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<String> songId;
  final Value<String> title;
  final Value<String> artistName;
  final Value<int?> genreId;
  final Value<String?> description;
  final Value<int> durationMs;
  final Value<String> audioUrl;
  final Value<String?> coverUrl;
  final Value<String?> coverLargeUrl;
  final Value<String?> expectedSha256;
  final Value<DownloadRowState> state;
  final Value<String> taskId;
  final Value<String?> audioFile;
  final Value<String?> coverFile;
  final Value<String?> contentType;
  final Value<int?> sizeBytes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.songId = const Value.absent(),
    this.title = const Value.absent(),
    this.artistName = const Value.absent(),
    this.genreId = const Value.absent(),
    this.description = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverLargeUrl = const Value.absent(),
    this.expectedSha256 = const Value.absent(),
    this.state = const Value.absent(),
    this.taskId = const Value.absent(),
    this.audioFile = const Value.absent(),
    this.coverFile = const Value.absent(),
    this.contentType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String songId,
    required String title,
    required String artistName,
    this.genreId = const Value.absent(),
    this.description = const Value.absent(),
    required int durationMs,
    required String audioUrl,
    this.coverUrl = const Value.absent(),
    this.coverLargeUrl = const Value.absent(),
    this.expectedSha256 = const Value.absent(),
    required DownloadRowState state,
    required String taskId,
    this.audioFile = const Value.absent(),
    this.coverFile = const Value.absent(),
    this.contentType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : songId = Value(songId),
       title = Value(title),
       artistName = Value(artistName),
       durationMs = Value(durationMs),
       audioUrl = Value(audioUrl),
       state = Value(state),
       taskId = Value(taskId),
       createdAt = Value(createdAt);
  static Insertable<Download> custom({
    Expression<String>? songId,
    Expression<String>? title,
    Expression<String>? artistName,
    Expression<int>? genreId,
    Expression<String>? description,
    Expression<int>? durationMs,
    Expression<String>? audioUrl,
    Expression<String>? coverUrl,
    Expression<String>? coverLargeUrl,
    Expression<String>? expectedSha256,
    Expression<int>? state,
    Expression<String>? taskId,
    Expression<String>? audioFile,
    Expression<String>? coverFile,
    Expression<String>? contentType,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (title != null) 'title': title,
      if (artistName != null) 'artist_name': artistName,
      if (genreId != null) 'genre_id': genreId,
      if (description != null) 'description': description,
      if (durationMs != null) 'duration_ms': durationMs,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (coverLargeUrl != null) 'cover_large_url': coverLargeUrl,
      if (expectedSha256 != null) 'expected_sha256': expectedSha256,
      if (state != null) 'state': state,
      if (taskId != null) 'task_id': taskId,
      if (audioFile != null) 'audio_file': audioFile,
      if (coverFile != null) 'cover_file': coverFile,
      if (contentType != null) 'content_type': contentType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? songId,
    Value<String>? title,
    Value<String>? artistName,
    Value<int?>? genreId,
    Value<String?>? description,
    Value<int>? durationMs,
    Value<String>? audioUrl,
    Value<String?>? coverUrl,
    Value<String?>? coverLargeUrl,
    Value<String?>? expectedSha256,
    Value<DownloadRowState>? state,
    Value<String>? taskId,
    Value<String?>? audioFile,
    Value<String?>? coverFile,
    Value<String?>? contentType,
    Value<int?>? sizeBytes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      songId: songId ?? this.songId,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      genreId: genreId ?? this.genreId,
      description: description ?? this.description,
      durationMs: durationMs ?? this.durationMs,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      coverLargeUrl: coverLargeUrl ?? this.coverLargeUrl,
      expectedSha256: expectedSha256 ?? this.expectedSha256,
      state: state ?? this.state,
      taskId: taskId ?? this.taskId,
      audioFile: audioFile ?? this.audioFile,
      coverFile: coverFile ?? this.coverFile,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (genreId.present) {
      map['genre_id'] = Variable<int>(genreId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (coverLargeUrl.present) {
      map['cover_large_url'] = Variable<String>(coverLargeUrl.value);
    }
    if (expectedSha256.present) {
      map['expected_sha256'] = Variable<String>(expectedSha256.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(
        $DownloadsTable.$converterstate.toSql(state.value),
      );
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (audioFile.present) {
      map['audio_file'] = Variable<String>(audioFile.value);
    }
    if (coverFile.present) {
      map['cover_file'] = Variable<String>(coverFile.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('songId: $songId, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('genreId: $genreId, ')
          ..write('description: $description, ')
          ..write('durationMs: $durationMs, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverLargeUrl: $coverLargeUrl, ')
          ..write('expectedSha256: $expectedSha256, ')
          ..write('state: $state, ')
          ..write('taskId: $taskId, ')
          ..write('audioFile: $audioFile, ')
          ..write('coverFile: $coverFile, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DownloadDatabase extends GeneratedDatabase {
  _$DownloadDatabase(QueryExecutor e) : super(e);
  $DownloadDatabaseManager get managers => $DownloadDatabaseManager(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [downloads];
}

typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String songId,
  required String title,
  required String artistName,
  Value<int?> genreId,
  Value<String?> description,
  required int durationMs,
  required String audioUrl,
  Value<String?> coverUrl,
  Value<String?> coverLargeUrl,
  Value<String?> expectedSha256,
  required DownloadRowState state,
  required String taskId,
  Value<String?> audioFile,
  Value<String?> coverFile,
  Value<String?> contentType,
  Value<int?> sizeBytes,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> songId,
  Value<String> title,
  Value<String> artistName,
  Value<int?> genreId,
  Value<String?> description,
  Value<int> durationMs,
  Value<String> audioUrl,
  Value<String?> coverUrl,
  Value<String?> coverLargeUrl,
  Value<String?> expectedSha256,
  Value<DownloadRowState> state,
  Value<String> taskId,
  Value<String?> audioFile,
  Value<String?> coverFile,
  Value<String?> contentType,
  Value<int?> sizeBytes,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$DownloadDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverLargeUrl => $composableBuilder(
    column: $table.coverLargeUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedSha256 => $composableBuilder(
    column: $table.expectedSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DownloadRowState, DownloadRowState, int>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioFile => $composableBuilder(
    column: $table.audioFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverFile => $composableBuilder(
    column: $table.coverFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$DownloadDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverLargeUrl => $composableBuilder(
    column: $table.coverLargeUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedSha256 => $composableBuilder(
    column: $table.expectedSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioFile => $composableBuilder(
    column: $table.audioFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverFile => $composableBuilder(
    column: $table.coverFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$DownloadDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get genreId =>
      $composableBuilder(column: $table.genreId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get coverLargeUrl => $composableBuilder(
    column: $table.coverLargeUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expectedSha256 => $composableBuilder(
    column: $table.expectedSha256,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DownloadRowState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get audioFile =>
      $composableBuilder(column: $table.audioFile, builder: (column) => column);

  GeneratedColumn<String> get coverFile =>
      $composableBuilder(column: $table.coverFile, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$DownloadDatabase,
          $DownloadsTable,
          Download,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (
            Download,
            BaseReferences<_$DownloadDatabase, $DownloadsTable, Download>,
          ),
          Download,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableManager(_$DownloadDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> songId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artistName = const Value.absent(),
                Value<int?> genreId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> audioUrl = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> coverLargeUrl = const Value.absent(),
                Value<String?> expectedSha256 = const Value.absent(),
                Value<DownloadRowState> state = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String?> audioFile = const Value.absent(),
                Value<String?> coverFile = const Value.absent(),
                Value<String?> contentType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                songId: songId,
                title: title,
                artistName: artistName,
                genreId: genreId,
                description: description,
                durationMs: durationMs,
                audioUrl: audioUrl,
                coverUrl: coverUrl,
                coverLargeUrl: coverLargeUrl,
                expectedSha256: expectedSha256,
                state: state,
                taskId: taskId,
                audioFile: audioFile,
                coverFile: coverFile,
                contentType: contentType,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String songId,
                required String title,
                required String artistName,
                Value<int?> genreId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required int durationMs,
                required String audioUrl,
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> coverLargeUrl = const Value.absent(),
                Value<String?> expectedSha256 = const Value.absent(),
                required DownloadRowState state,
                required String taskId,
                Value<String?> audioFile = const Value.absent(),
                Value<String?> coverFile = const Value.absent(),
                Value<String?> contentType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                songId: songId,
                title: title,
                artistName: artistName,
                genreId: genreId,
                description: description,
                durationMs: durationMs,
                audioUrl: audioUrl,
                coverUrl: coverUrl,
                coverLargeUrl: coverLargeUrl,
                expectedSha256: expectedSha256,
                state: state,
                taskId: taskId,
                audioFile: audioFile,
                coverFile: coverFile,
                contentType: contentType,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadsTable, Download>(table),
                  BaseReferences<_$DownloadDatabase, $DownloadsTable, Download>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$DownloadDatabase,
      $DownloadsTable,
      Download,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (Download, BaseReferences<_$DownloadDatabase, $DownloadsTable, Download>),
      Download,
      PrefetchHooks Function()
    >;

class $DownloadDatabaseManager {
  final _$DownloadDatabase _db;
  $DownloadDatabaseManager(this._db);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
}
