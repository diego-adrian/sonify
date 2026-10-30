import 'package:flutter/widgets.dart';

/// Tocar fuera de un campo de texto cierra el teclado en toda la app. Flutter
/// solo lo hace en escritorio; en el teléfono el campo seguiría enfocado.
///
/// Se cambia la acción por defecto en lugar de un `GestureDetector` en la raíz
/// porque aquel no se entera de los toques que atiende un botón o una fila.
/// Los campos de texto son un mismo grupo: pasar de uno a otro no lo cierra.
class TapOutsideDismissesKeyboard extends StatelessWidget {
  const TapOutsideDismissesKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      EditableTextTapOutsideIntent:
          CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              return null;
            },
          ),
    },
    child: child,
  );
}
