/// Usuario autenticado. Todo usuario es también artista de sí mismo.
///
/// [id] es siempre el uuid de Supabase (`auth.users.id`), nunca el ID del
/// proveedor de login ni el email.
final class AppUser {
  const AppUser({required this.id, required this.displayName, this.avatarUrl});

  final String id;
  final String displayName;
  final String? avatarUrl;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.displayName == displayName &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, displayName, avatarUrl);
}
