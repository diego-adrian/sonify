import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../library/domain/library.dart';
import '../../library/presentation/library_providers.dart';
import '../../../core/widgets/visible_center.dart';

/// Premium (menú inferior). Gratis: qué incluye el límite de canciones y qué
/// suma Premium. El pago todavía no existe (tabla `subscriptions` lista para
/// cuando lleguen los webhooks de las tiendas).
class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.premiumTitle, style: AppTypography.appBarTitle),
      ),
      body: switch (state) {
        AsyncValue(:final value?) => ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: value.account.unlimited
              ? _premium(context)
              : _free(context, value),
        ),
        AsyncValue(hasError: true) => VisibleCenter(
          child: TextButton(
            onPressed: () => ref.invalidate(libraryProvider),
            child: Text(l10n.retry),
          ),
        ),
        _ => const VisibleCenter(child: CircularProgressIndicator()),
      },
    );
  }

  static List<Widget> _premium(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return [
      const SizedBox(height: 24),
      Icon(Icons.workspace_premium_rounded, size: 72, color: scheme.primary),
      const SizedBox(height: 16),
      Text(
        l10n.premiumActive,
        textAlign: TextAlign.center,
        style: AppTypography.title.copyWith(color: scheme.onSurface),
      ),
      const SizedBox(height: 8),
      Text(
        l10n.premiumActiveBody,
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
      ),
    ];
  }

  static List<Widget> _free(BuildContext context, Library library) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final account = library.account;
    final limit = account.libraryLimit ?? 0;
    final price = _price(account);

    return [
      Text(
        l10n.premiumFreeIntro(limit),
        style: AppTypography.body.copyWith(color: scheme.onSurface),
      ),
      const SizedBox(height: 12),
      _Benefit(
        icon: Icons.graphic_eq_rounded,
        text: l10n.premiumBenefitStreaming,
      ),
      _Benefit(
        icon: Icons.download_for_offline_outlined,
        text: l10n.premiumBenefitOffline,
      ),
      _Benefit(
        icon: Icons.lock_clock_outlined,
        text: l10n.premiumBenefitBackground,
      ),
      _Benefit(
        icon: Icons.queue_music_rounded,
        text: l10n.premiumBenefitPlaylists,
      ),
      const SizedBox(height: 12),
      Text(
        l10n.premiumUsage(library.songs.length, limit),
        style: AppTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: limit == 0 ? 1 : (library.songs.length / limit).clamp(0, 1),
          minHeight: 6,
          color: scheme.primary,
          backgroundColor: scheme.primaryContainer,
        ),
      ),
      const SizedBox(height: 32),
      Text(
        l10n.premiumWithPremium,
        style: AppTypography.title.copyWith(color: scheme.onSurface),
      ),
      const SizedBox(height: 8),
      _Benefit(
        icon: Icons.all_inclusive_rounded,
        text: l10n.premiumUnlimited,
        highlighted: true,
      ),
      const SizedBox(height: 24),
      FilledButton(
        // Sin pagos todavía.
        onPressed: null,
        child: Text(price == null ? l10n.premiumTitle : l10n.premiumCta(price)),
      ),
      const SizedBox(height: 8),
      Text(
        l10n.premiumSoon,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      ),
    ];
  }

  static String? _price(Account account) {
    final cents = account.premiumPriceCents;
    final currency = account.premiumCurrency;
    if (cents == null || currency == null) return null;
    return NumberFormat.simpleCurrency(
      locale: 'es',
      name: currency,
    ).format(cents / 100);
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.text,
    this.highlighted = false,
  });

  final IconData icon;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: highlighted ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
