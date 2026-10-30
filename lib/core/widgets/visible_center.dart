import 'package:flutter/widgets.dart';

/// Centra [child] en la parte visible de una pestaña: el contenido sigue
/// detrás del menú inferior (`extendBody`), cuyo alto llega como margen
/// inferior (`MediaQuery.paddingOf(context).bottom`).
class VisibleCenter extends StatelessWidget {
  const VisibleCenter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
    child: Center(child: child),
  );
}
