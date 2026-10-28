import 'dart:async';

import 'package:sonify/core/network/network_status.dart';

final class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus({this._online = true});

  bool _online;
  final _changes = StreamController<bool>.broadcast();

  set online(bool value) {
    _online = value;
    _changes.add(value);
  }

  @override
  Stream<bool> watchOnline() async* {
    yield _online;
    yield* _changes.stream;
  }

  Future<void> dispose() => _changes.close();
}
