import 'package:flutter/services.dart';

/// Formatter that automatically converts commas (,) to dots (.) in decimal text input
/// while maintaining correct selection/cursor position.
class DecimalCommaInputFormatter extends TextInputFormatter {
  const DecimalCommaInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.text.contains(',')) {
      return newValue;
    }

    final String updatedText = newValue.text.replaceAll(',', '.');
    return newValue.copyWith(
      text: updatedText,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}
