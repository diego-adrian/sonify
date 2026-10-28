import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';

AppUser appUserFromSupabase(User user) {
  final meta = user.userMetadata ?? const <String, dynamic>{};
  final emailName = user.email?.split('@').first;

  return AppUser(
    id: user.id,
    displayName:
        _nonEmpty(meta['full_name']) ??
        _nonEmpty(meta['name']) ??
        _nonEmpty(emailName) ??
        'Artista',
    avatarUrl: _nonEmpty(meta['avatar_url']) ?? _nonEmpty(meta['picture']),
  );
}

String? _nonEmpty(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
