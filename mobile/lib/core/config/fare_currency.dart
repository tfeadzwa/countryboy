/// Supported ticket currencies and fare validation rules.
///
/// USD / ZWL: whole numbers only (multiples of 1).
/// ZAR: whole numbers, minimum 20, multiples of 10.
library;

const kTicketCurrencies = ['USD', 'ZWL', 'ZAR'];

String currencyLabel(String code) => switch (code) {
      'USD' => 'USD (\$)',
      'ZWL' => 'ZWL (Z\$)',
      'ZAR' => 'ZAR (R)',
      _ => code,
    };

String currencyHelperText(String code) {
  switch (code) {
    case 'USD':
    case 'ZWL':
      return 'Whole amounts only (e.g. 1, 2, 5, 10)';
    case 'ZAR':
      return 'From 20 upward, in steps of 10 (e.g. 20, 30, 40)';
    default:
      return 'Enter the fare amount';
  }
}

/// Returns null when [amount] is valid for [currency]; otherwise an error message.
String? validateFareAmount(
  String currency,
  num? amount, {
  String label = 'Amount',
}) {
  if (amount == null) {
    return 'Enter the ${label.toLowerCase()}.';
  }
  if (amount <= 0) {
    return '$label must be greater than 0.';
  }

  final asDouble = amount.toDouble();
  if (asDouble != asDouble.roundToDouble()) {
    return '$label must be a whole number (no cents).';
  }

  final whole = asDouble.round();

  switch (currency) {
    case 'USD':
    case 'ZWL':
      return null;
    case 'ZAR':
      if (whole < 20) {
        return '$label for ZAR must be at least 20.';
      }
      if (whole % 10 != 0) {
        return '$label for ZAR must be a multiple of 10.';
      }
      return null;
    default:
      return 'Unsupported currency.';
  }
}

/// Parses conductor-entered fare text. Commas stripped; decimals rejected by validator.
double? parseFareInput(String raw) {
  final cleaned = raw.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
