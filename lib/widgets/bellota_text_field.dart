import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

/// Campo de texto estilizado con la paleta visual de Bellota.
///
/// Widget reutilizable que reemplaza las implementaciones duplicadas
/// que existían en [LoginScreen] y [RegisterScreen].
///
/// Ejemplo de uso:
/// ```dart
/// BellotaTextField(
///   controller: _emailController,
///   label: 'Correo electrónico',
///   hint: 'tu@correo.com',
///   prefixIcon: Icons.email_outlined,
///   keyboardType: TextInputType.emailAddress,
///   validator: (v) => v!.isEmpty ? 'Ingresa tu correo' : null,
/// )
/// ```
class BellotaTextField extends StatelessWidget {
  /// Controlador de texto del campo.
  final TextEditingController controller;

  /// Etiqueta flotante que describe el campo.
  final String label;

  /// Texto de ayuda visible cuando el campo está vacío.
  final String hint;

  /// Ícono al inicio del campo.
  final IconData prefixIcon;

  /// Si `true`, el texto se muestra oculto (para contraseñas).
  final bool obscureText;

  /// Widget opcional al final del campo (ej: botón de visibilidad).
  final Widget? suffixIcon;

  /// Tipo de teclado a mostrar (ej: email, numérico).
  final TextInputType? keyboardType;

  /// Función de validación. Retorna un mensaje de error o `null` si es válido.
  final String? Function(String?)? validator;

  /// Nodo de foco para control de teclado.
  final FocusNode? focusNode;

  /// Acci�n del teclado virtual (ej: 'Siguiente', 'Hecho').
  final TextInputAction? textInputAction;

  /// Sugerencias de autocompletado del SO.
  final Iterable<String>? autofillHints;

  const BellotaTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(color: Theme.of(context).bellotaColors.blanco),
      cursorColor: Theme.of(context).bellotaColors.blanco,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          prefixIcon,
          color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.75),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

