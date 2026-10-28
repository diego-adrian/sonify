import 'dart:async';

import 'package:sonify/features/catalog/domain/song.dart';
import 'package:sonify/features/downloads/domain/download_entry.dart';
import 'package:sonify/features/downloads/domain/download_ports.dart';

final class FakeDownloadRepository implements DownloadRepository {
  final entries = <DownloadEntry>[];
  final _changes = StreamController<List<DownloadEntry>>.broadcast();
  int removeAllCalls = 0;
  int suspendCalls = 0;

  @override
  Stream<List<DownloadEntry>> watchAll() async* {
    yield List.of(entries);
    yield* _changes.stream;
  }

  @override
  Stream<Map<String, double>> watchProgress() => Stream.value(const {});

  @override
  Future<Set<String>> activeSongIds() async => {
    for (final entry in entries)
      if (entry.state != DownloadState.failed) entry.song.id,
  };

  @override
  Future<void> enqueue(List<Song> songs) async {
    entries.addAll([
      for (final song in songs)
        DownloadEntry(song: song, state: DownloadState.queued),
    ]);
    _changes.add(List.of(entries));
  }

  @override
  Future<void> remove(String songId) async {
    entries.removeWhere((e) => e.song.id == songId);
    _changes.add(List.of(entries));
  }

  @override
  Future<void> removeAll() async {
    removeAllCalls++;
    entries.clear();
    _changes.add(const []);
  }

  @override
  Future<void> suspend() async => suspendCalls++;

  Future<void> dispose() => _changes.close();
}

final class FakeStorageSpace implements StorageSpace {
  FakeStorageSpace(this.free);

  int? free;

  @override
  Future<int?> freeBytes() async => free;
}
