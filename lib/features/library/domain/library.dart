import '../../catalog/domain/song.dart';

/// Lo que el backend sabe de la cuenta con sesión (RPC `my_account`).
final class Account {
  const Account({
    required this.isPremium,
    required this.isAdmin,
    this.libraryLimit,
    this.premiumPriceCents,
    this.premiumCurrency,
  });

  /// Sin datos todavía (primer arranque sin red): no se limita nada; el
  /// backend sigue sin firmar el audio de lo que no se puede escuchar.
  static const unknown = Account(isPremium: true, isAdmin: false);

  final bool isPremium;

  /// Solo los admins suben canciones.
  final bool isAdmin;

  /// Canciones que puede guardar (y escuchar) una cuenta gratis; `null` =
  /// sin límite.
  final int? libraryLimit;

  final int? premiumPriceCents;
  final String? premiumCurrency;

  bool get unlimited => isPremium || libraryLimit == null;
}

/// Lista del usuario. Sus canciones son siempre de la biblioteca: agregar a
/// una playlist guarda la canción.
final class Playlist {
  const Playlist({required this.id, required this.name, required this.songIds});

  final String id;
  final String name;

  /// En el orden en que se agregaron.
  final List<String> songIds;
}

/// Biblioteca del usuario: las canciones que guardó del catálogo (una canción
/// la pueden guardar n usuarios) y sus playlists.
final class Library {
  Library({required this.account, required this.songs, required this.playlists})
    : _byId = {for (final song in songs) song.id: song};

  static final empty = Library(
    account: Account.unknown,
    songs: const [],
    playlists: const [],
  );

  final Account account;

  /// Guardadas, la más reciente primero. Traen el audio firmado.
  final List<Song> songs;
  final List<Playlist> playlists;
  final Map<String, Song> _byId;

  bool contains(String songId) => _byId.containsKey(songId);

  Song? song(String songId) => _byId[songId];

  /// Una cuenta gratis solo escucha lo que guardó.
  bool canPlay(String songId) => account.unlimited || contains(songId);

  /// Cuántas puede guardar todavía; `null` = sin límite.
  int? get remaining => account.unlimited
      ? null
      : (account.libraryLimit! - songs.length).clamp(0, account.libraryLimit!);

  bool get isFull => remaining == 0;

  Playlist? playlist(String id) =>
      playlists.where((playlist) => playlist.id == id).firstOrNull;

  /// Canciones de [playlist] (las que siguen en la biblioteca).
  List<Song> songsOf(Playlist playlist) => [
    for (final id in playlist.songIds) ?_byId[id],
  ];
}
