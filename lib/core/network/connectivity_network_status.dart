import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'network_status.dart';

/// Adaptador con `connectivity_plus`: eventos del sistema (NWPathMonitor en
/// iOS, ConnectivityManager en Android), sin polling.
final class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus(this._connectivity);

  final Connectivity _connectivity;

  @override
  Stream<bool> watchOnline() async* {
    try {
      yield _isOnline(await _connectivity.checkConnectivity());
      yield* _connectivity.onConnectivityChanged.map(_isOnline);
    } on Exception catch (error) {
      // Si no se puede consultar, se asume que hay red: es lo que pasaba
      // antes de tener este aviso.
      debugPrint('Conectividad no disponible: $error');
      yield true;
    }
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
