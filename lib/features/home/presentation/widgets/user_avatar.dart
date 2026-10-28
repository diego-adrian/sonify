import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 60,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: AppTypography.body.copyWith(
            color: scheme.primary,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
    final imageUrl = this.imageUrl;

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: imageUrl == null
            ? fallback
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
