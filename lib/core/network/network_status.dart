/// Puerto: ¿el dispositivo tiene una red (Wi-Fi, datos…)?
///
/// Solo sabe si hay interfaz de red, no si hay internet de verdad: con señal
/// débil puede decir que sí aunque las peticiones no lleguen (de eso se ocupa
/// el timeout del catálogo).
abstract interface class NetworkStatus {
  /// Emite el estado actual y luego cada cambio, sin repetir valores.
  Stream<bool> watchOnline();
}
