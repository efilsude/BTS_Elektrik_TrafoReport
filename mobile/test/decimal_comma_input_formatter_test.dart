import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trafo_report_mobile/utils/decimal_comma_input_formatter.dart';

void main() {
  group('DecimalCommaInputFormatter Tests', () {
    const DecimalCommaInputFormatter formatter = DecimalCommaInputFormatter();

    test('replaces single comma with dot and keeps cursor position', () {
      const TextEditingValue oldValue = TextEditingValue(
        text: '9',
        selection: TextSelection.collapsed(offset: 1),
      );
      const TextEditingValue newValue = TextEditingValue(
        text: '9,',
        selection: TextSelection.collapsed(offset: 2),
      );

      final TextEditingValue result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('9.'));
      expect(result.selection.baseOffset, equals(2));
      expect(result.selection.extentOffset, equals(2));
    });

    test('replaces pasted text containing comma with dot', () {
      const TextEditingValue oldValue = TextEditingValue.empty;
      const TextEditingValue newValue = TextEditingValue(
        text: '12,345',
        selection: TextSelection.collapsed(offset: 6),
      );

      final TextEditingValue result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('12.345'));
      expect(result.selection.baseOffset, equals(6));
    });

    test('leaves text with dot untouched', () {
      const TextEditingValue oldValue = TextEditingValue(
        text: '12.',
        selection: TextSelection.collapsed(offset: 3),
      );
      const TextEditingValue newValue = TextEditingValue(
        text: '12.5',
        selection: TextSelection.collapsed(offset: 4),
      );

      final TextEditingValue result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('12.5'));
    });
  });
}
