import 'package:flutter/services.dart';

class WeightInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');
    if (text.length > 5) {
      text = text.substring(0, 5);
    }
    if (text.length > 2) {
      text = '${text.substring(0, text.length - 2)}.${text.substring(text.length - 2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
