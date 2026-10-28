import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../home_providers.dart';
import '../../../../core/theme/app_typography.dart';

/// Pestañas "Similares" / "A continuación" (Figma node 106:97).
class HomeTabs extends StatelessWidget {
  const HomeTabs({super.key, required this.selected, required this.onSelected});

  static const height = 56.0;

  final HomeTab selected;
  final ValueChanged<HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          _Tab(
            icon: Icons.auto_awesome_rounded,
            label: l10n.tabSimilar,
            selected: selected == HomeTab.similar,
            onTap: () => onSelected(HomeTab.similar),
          ),
          _Tab(
            icon: Icons.format_list_bulleted_rounded,
            label: l10n.tabUpNext,
            selected: selected == HomeTab.upNext,
            onTap: () => onSelected(HomeTab.upNext),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22, color: scheme.primary),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: selected
                            ? AppTypography.title.copyWith(
                                color: scheme.onSurface,
                              )
                            : AppTypography.title.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w300,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 2,
                child: selected
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0),
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
