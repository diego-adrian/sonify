// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listening_cache_database.dart';

// ignore_for_file: type=lint
class $CachedSongsTable extends CachedSongs
    with TableInfo<$CachedSongsTable, CachedSong> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSongsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _audioFileMeta = const VerificationMeta(
    'audioFile',
  );
  @override
  late final GeneratedColumn<String> audioFile = GeneratedColumn<String>(
    'audio_file',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
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
    durationMs,
    audioUrl,
    coverUrl,
    coverLargeUrl,
    audioFile,
    contentType,
    sizeBytes,
    lastPlayedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSong> instance, {
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
    if (data.containsKey('audio_file')) {
      context.handle(
        _audioFileMeta,
        audioFile.isAcceptableOrUnknown(data['audio_file']!, _audioFileMeta),
      );
    } else if (isInserting) {
      context.missing(_audioFileMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPlayedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId};
  @override
  CachedSong map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSong(
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
      audioFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_file'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      )!,
    );
  }

  @override
  $CachedSongsTable createAlias(String alias) {
    return $CachedSongsTable(attachedDatabase, alias);
  }
}

class CachedSong extends DataClass implements Insertable<CachedSong> {
  final String songId;
  final String title;
  final String artistName;
  final int? genreId;
  final int durationMs;
  final String audioUrl;
  final String? coverUrl;
  final String? coverLargeUrl;
  final String audioFile;
  final String contentType;

  /// Bytes del audio cifrado en disco.
  final int sizeBytes;

  /// Al llenarse la caché se borra primero la de fecha más vieja.
  final DateTime lastPlayedAt;
  const CachedSong({
    required this.songId,
    required this.title,
    required this.artistName,
    this.genreId,
    required this.durationMs,
    required this.audioUrl,
    this.coverUrl,
    this.coverLargeUrl,
    required this.audioFile,
    required this.contentType,
    required this.sizeBytes,
    required this.lastPlayedAt,
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
    map['duration_ms'] = Variable<int>(durationMs);
    map['audio_url'] = Variable<String>(audioUrl);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || coverLargeUrl != null) {
      map['cover_large_url'] = Variable<String>(coverLargeUrl);
    }
    map['audio_file'] = Variable<String>(audioFile);
    map['content_type'] = Variable<String>(contentType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    return map;
  }

  CachedSongsCompanion toCompanion(bool nullToAbsent) {
    return CachedSongsCompanion(
      songId: Value(songId),
      title: Value(title),
      artistName: Value(artistName),
      genreId: genreId == null && nullToAbsent
          ? const Value.absent()
          : Value(genreId),
      durationMs: Value(durationMs),
      audioUrl: Value(audioUrl),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      coverLargeUrl: coverLargeUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverLargeUrl),
      audioFile: Value(audioFile),
      contentType: Value(contentType),
      sizeBytes: Value(sizeBytes),
      lastPlayedAt: Value(lastPlayedAt),
    );
  }

  factory CachedSong.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSong(
      songId: serializer.fromJson<String>(json['songId']),
      title: serializer.fromJson<String>(json['title']),
      artistName: serializer.fromJson<String>(json['artistName']),
      genreId: serializer.fromJson<int?>(json['genreId']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      audioUrl: serializer.fromJson<String>(json['audioUrl']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      coverLargeUrl: serializer.fromJson<String?>(json['coverLargeUrl']),
      audioFile: serializer.fromJson<String>(json['audioFile']),
      contentType: serializer.fromJson<String>(json['contentType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      lastPlayedAt: serializer.fromJson<DateTime>(json['lastPlayedAt']),
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
      'durationMs': serializer.toJson<int>(durationMs),
      'audioUrl': serializer.toJson<String>(audioUrl),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'coverLargeUrl': serializer.toJson<String?>(coverLargeUrl),
      'audioFile': serializer.toJson<String>(audioFile),
      'contentType': serializer.toJson<String>(contentType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'lastPlayedAt': serializer.toJson<DateTime>(lastPlayedAt),
    };
  }

  CachedSong copyWith({
    String? songId,
    String? title,
    String? artistName,
    Value<int?> genreId = const Value.absent(),
    int? durationMs,
    String? audioUrl,
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> coverLargeUrl = const Value.absent(),
    String? audioFile,
    String? contentType,
    int? sizeBytes,
    DateTime? lastPlayedAt,
  }) => CachedSong(
    songId: songId ?? this.songId,
    title: title ?? this.title,
    artistName: artistName ?? this.artistName,
    genreId: genreId.present ? genreId.value : this.genreId,
    durationMs: durationMs ?? this.durationMs,
    audioUrl: audioUrl ?? this.audioUrl,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    coverLargeUrl: coverLargeUrl.present
        ? coverLargeUrl.value
        : this.coverLargeUrl,
    audioFile: audioFile ?? this.audioFile,
    contentType: contentType ?? this.contentType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
  );
  CachedSong copyWithCompanion(CachedSongsCompanion data) {
    return CachedSong(
      songId: data.songId.present ? data.songId.value : this.songId,
      title: data.title.present ? data.title.value : this.title,
      artistName: data.artistName.present
          ? data.artistName.value
          : this.artistName,
      genreId: data.genreId.present ? data.genreId.value : this.genreId,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      coverLargeUrl: data.coverLargeUrl.present
          ? data.coverLargeUrl.value
          : this.coverLargeUrl,
      audioFile: data.audioFile.present ? data.audioFile.value : this.audioFile,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSong(')
          ..write('songId: $songId, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('genreId: $genreId, ')
          ..write('durationMs: $durationMs, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverLargeUrl: $coverLargeUrl, ')
          ..write('audioFile: $audioFile, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    songId,
    title,
    artistName,
    genreId,
    durationMs,
    audioUrl,
    coverUrl,
    coverLargeUrl,
    audioFile,
    contentType,
    sizeBytes,
    lastPlayedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSong &&
          other.songId == this.songId &&
          other.title == this.title &&
          other.artistName == this.artistName &&
          other.genreId == this.genreId &&
          other.durationMs == this.durationMs &&
          other.audioUrl == this.audioUrl &&
          other.coverUrl == this.coverUrl &&
          other.coverLargeUrl == this.coverLargeUrl &&
          other.audioFile == this.audioFile &&
          other.contentType == this.contentType &&
          other.sizeBytes == this.sizeBytes &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class CachedSongsCompanion extends UpdateCompanion<CachedSong> {
  final Value<String> songId;
  final Value<String> title;
  final Value<String> artistName;
  final Value<int?> genreId;
  final Value<int> durationMs;
  final Value<String> audioUrl;
  final Value<String?> coverUrl;
  final Value<String?> coverLargeUrl;
  final Value<String> audioFile;
  final Value<String> contentType;
  final Value<int> sizeBytes;
  final Value<DateTime> lastPlayedAt;
  final Value<int> rowid;
  const CachedSongsCompanion({
    this.songId = const Value.absent(),
    this.title = const Value.absent(),
    this.artistName = const Value.absent(),
    this.genreId = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverLargeUrl = const Value.absent(),
    this.audioFile = const Value.absent(),
    this.contentType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSongsCompanion.insert({
    required String songId,
    required String title,
    required String artistName,
    this.genreId = const Value.absent(),
    required int durationMs,
    required String audioUrl,
    this.coverUrl = const Value.absent(),
    this.coverLargeUrl = const Value.absent(),
    required String audioFile,
    required String contentType,
    required int sizeBytes,
    required DateTime lastPlayedAt,
    this.rowid = const Value.absent(),
  }) : songId = Value(songId),
       title = Value(title),
       artistName = Value(artistName),
       durationMs = Value(durationMs),
       audioUrl = Value(audioUrl),
       audioFile = Value(audioFile),
       contentType = Value(contentType),
       sizeBytes = Value(sizeBytes),
       lastPlayedAt = Value(lastPlayedAt);
  static Insertable<CachedSong> custom({
    Expression<String>? songId,
    Expression<String>? title,
    Expression<String>? artistName,
    Expression<int>? genreId,
    Expression<int>? durationMs,
    Expression<String>? audioUrl,
    Expression<String>? coverUrl,
    Expression<String>? coverLargeUrl,
    Expression<String>? audioFile,
    Expression<String>? contentType,
    Expression<int>? sizeBytes,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (title != null) 'title': title,
      if (artistName != null) 'artist_name': artistName,
      if (genreId != null) 'genre_id': genreId,
      if (durationMs != null) 'duration_ms': durationMs,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (coverLargeUrl != null) 'cover_large_url': coverLargeUrl,
      if (audioFile != null) 'audio_file': audioFile,
      if (contentType != null) 'content_type': contentType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSongsCompanion copyWith({
    Value<String>? songId,
    Value<String>? title,
    Value<String>? artistName,
    Value<int?>? genreId,
    Value<int>? durationMs,
    Value<String>? audioUrl,
    Value<String?>? coverUrl,
    Value<String?>? coverLargeUrl,
    Value<String>? audioFile,
    Value<String>? contentType,
    Value<int>? sizeBytes,
    Value<DateTime>? lastPlayedAt,
    Value<int>? rowid,
  }) {
    return CachedSongsCompanion(
      songId: songId ?? this.songId,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      genreId: genreId ?? this.genreId,
      durationMs: durationMs ?? this.durationMs,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      coverLargeUrl: coverLargeUrl ?? this.coverLargeUrl,
      audioFile: audioFile ?? this.audioFile,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
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
    if (audioFile.present) {
      map['audio_file'] = Variable<String>(audioFile.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSongsCompanion(')
          ..write('songId: $songId, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('genreId: $genreId, ')
          ..write('durationMs: $durationMs, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverLargeUrl: $coverLargeUrl, ')
          ..write('audioFile: $audioFile, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ListeningCacheDatabase extends GeneratedDatabase {
  _$ListeningCacheDatabase(QueryExecutor e) : super(e);
  $ListeningCacheDatabaseManager get managers =>
      $ListeningCacheDatabaseManager(this);
  late final $CachedSongsTable cachedSongs = $CachedSongsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cachedSongs];
}

typedef $$CachedSongsTableCreateCompanionBuilder =
    CachedSongsCompanion Function({
      required String songId,
      required String title,
      required String artistName,
      Value<int?> genreId,
      required int durationMs,
      required String audioUrl,
      Value<String?> coverUrl,
      Value<String?> coverLargeUrl,
      required String audioFile,
      required String contentType,
      required int sizeBytes,
      required DateTime lastPlayedAt,
      Value<int> rowid,
    });
typedef $$CachedSongsTableUpdateCompanionBuilder =
    CachedSongsCompanion Function({
      Value<String> songId,
      Value<String> title,
      Value<String> artistName,
      Value<int?> genreId,
      Value<int> durationMs,
      Value<String> audioUrl,
      Value<String?> coverUrl,
      Value<String?> coverLargeUrl,
      Value<String> audioFile,
      Value<String> contentType,
      Value<int> sizeBytes,
      Value<DateTime> lastPlayedAt,
      Value<int> rowid,
    });

class $$CachedSongsTableFilterComposer
    extends Composer<_$ListeningCacheDatabase, $CachedSongsTable> {
  $$CachedSongsTableFilterComposer({
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

  ColumnFilters<String> get audioFile => $composableBuilder(
    column: $table.audioFile,
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

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSongsTableOrderingComposer
    extends Composer<_$ListeningCacheDatabase, $CachedSongsTable> {
  $$CachedSongsTableOrderingComposer({
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

  ColumnOrderings<String> get audioFile => $composableBuilder(
    column: $table.audioFile,
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

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSongsTableAnnotationComposer
    extends Composer<_$ListeningCacheDatabase, $CachedSongsTable> {
  $$CachedSongsTableAnnotationComposer({
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

  GeneratedColumn<String> get audioFile =>
      $composableBuilder(column: $table.audioFile, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );
}

class $$CachedSongsTableTableManager
    extends
        RootTableManager<
          _$ListeningCacheDatabase,
          $CachedSongsTable,
          CachedSong,
          $$CachedSongsTableFilterComposer,
          $$CachedSongsTableOrderingComposer,
          $$CachedSongsTableAnnotationComposer,
          $$CachedSongsTableCreateCompanionBuilder,
          $$CachedSongsTableUpdateCompanionBuilder,
          (
            CachedSong,
            BaseReferences<
              _$ListeningCacheDatabase,
              $CachedSongsTable,
              CachedSong
            >,
          ),
          CachedSong,
          PrefetchHooks Function()
        > {
  $$CachedSongsTableTableManager(
    _$ListeningCacheDatabase db,
    $CachedSongsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> songId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artistName = const Value.absent(),
                Value<int?> genreId = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> audioUrl = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> coverLargeUrl = const Value.absent(),
                Value<String> audioFile = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> lastPlayedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSongsCompanion(
                songId: songId,
                title: title,
                artistName: artistName,
                genreId: genreId,
                durationMs: durationMs,
                audioUrl: audioUrl,
                coverUrl: coverUrl,
                coverLargeUrl: coverLargeUrl,
                audioFile: audioFile,
                contentType: contentType,
                sizeBytes: sizeBytes,
                lastPlayedAt: lastPlayedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String songId,
                required String title,
                required String artistName,
                Value<int?> genreId = const Value.absent(),
                required int durationMs,
                required String audioUrl,
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> coverLargeUrl = const Value.absent(),
                required String audioFile,
                required String contentType,
                required int sizeBytes,
                required DateTime lastPlayedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedSongsCompanion.insert(
                songId: songId,
                title: title,
                artistName: artistName,
                genreId: genreId,
                durationMs: durationMs,
                audioUrl: audioUrl,
                coverUrl: coverUrl,
                coverLargeUrl: coverLargeUrl,
                audioFile: audioFile,
                contentType: contentType,
                sizeBytes: sizeBytes,
                lastPlayedAt: lastPlayedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedSongsTable, CachedSong>(table),
                  BaseReferences<
                    _$ListeningCacheDatabase,
                    $CachedSongsTable,
                    CachedSong
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSongsTableProcessedTableManager =
    ProcessedTableManager<
      _$ListeningCacheDatabase,
      $CachedSongsTable,
      CachedSong,
      $$CachedSongsTableFilterComposer,
      $$CachedSongsTableOrderingComposer,
      $$CachedSongsTableAnnotationComposer,
      $$CachedSongsTableCreateCompanionBuilder,
      $$CachedSongsTableUpdateCompanionBuilder,
      (
        CachedSong,
        BaseReferences<_$ListeningCacheDatabase, $CachedSongsTable, CachedSong>,
      ),
      CachedSong,
      PrefetchHooks Function()
    >;

class $ListeningCacheDatabaseManager {
  final _$ListeningCacheDatabase _db;
  $ListeningCacheDatabaseManager(this._db);
  $$CachedSongsTableTableManager get cachedSongs =>
      $$CachedSongsTableTableManager(_db, _db.cachedSongs);
}
