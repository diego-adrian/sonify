import 'package:flutter_test/flutter_test.dart';
import 'package:sonify/features/auth/infrastructure/supabase_user_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user({Map<String, dynamic>? meta, String? email}) => User(
  id: 'uuid-1',
  appMetadata: const {},
  userMetadata: meta,
  aud: 'authenticated',
  email: email,
  createdAt: '2026-10-27T00:00:00Z',
);

void main() {
  test('usa nombre y foto de Google', () {
    final user = appUserFromSupabase(
      _user(meta: {'full_name': 'Cinthia Pérez', 'avatar_url': 'https://a/b'}),
    );

    expect(user.id, 'uuid-1');
    expect(user.displayName, 'Cinthia Pérez');
    expect(user.avatarUrl, 'https://a/b');
  });

  test('cae al email y luego a "Artista"', () {
    expect(
      appUserFromSupabase(_user(meta: {'full_name': '  '}, email: 'ana@x.com'))
          .displayName,
      'ana',
    );
    expect(appUserFromSupabase(_user()).displayName, 'Artista');
  });
}
