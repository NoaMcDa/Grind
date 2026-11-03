import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';

/// Text input with the 2.5 px ink border. [pill] makes single-line fields
/// fully rounded; otherwise the corner radius is 16.
class StickerTextField extends StatelessWidget {
  const StickerTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.pill = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;

  /// Non-null puts the field in its error state (red border + message).
  final String? errorText;
  final bool pill;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;

  OutlineInputBorder _border(double radius, Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color, width: AppStroke.border),
  );

  @override
  Widget build(BuildContext context) {
    final radius = pill && maxLines == 1 ? AppRadii.pill : AppRadii.cardSmall;
    final hasError = errorText != null;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppText.body(),
      cursorColor: AppColors.violet,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.card,
        constraints: const BoxConstraints(minHeight: 44),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: pill ? 20 : 16,
          vertical: 12,
        ),
        border: _border(radius, AppColors.ink),
        enabledBorder: _border(
          radius,
          hasError ? AppColors.error : AppColors.ink,
        ),
        focusedBorder: _border(
          radius,
          hasError ? AppColors.error : AppColors.violet,
        ),
        errorBorder: _border(radius, AppColors.error),
        focusedErrorBorder: _border(radius, AppColors.error),
        disabledBorder: _border(radius, AppColors.muted),
        labelStyle: AppText.body(color: AppColors.muted),
        hintStyle: AppText.body(color: AppColors.muted),
        errorStyle: AppText.bold(size: 12, color: AppColors.error),
      ),
    );
  }
}
