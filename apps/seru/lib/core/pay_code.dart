import 'dart:convert';

/// Parsed ZIBA receive-code payload. The APK pays this, not a username.
class ZibaPayPayload {
  const ZibaPayPayload({required this.code, this.amount, this.uri});

  final String code;
  final String? amount;
  final String? uri;

  String get displayCode => code;
}

class PayIntent {
  const PayIntent({required this.code, required this.amount});

  final String code;
  final String amount;
}

class ZibaPayCodes {
  static final _codeRe = RegExp(r'^ZBA-[A-HJ-NP-Z2-9]{6}$');

  static String normalize(String raw) {
    var s = raw.trim().toUpperCase();
    s = s.replaceAll(' ', '').replaceAll('_', '');
    const prefixUri = 'ZIBA://PAY/';
    if (s.startsWith(prefixUri)) {
      s = s.substring(prefixUri.length);
    }
    if (s.startsWith('PAY/')) {
      s = s.substring(4);
    }
    if (!s.startsWith('ZBA-')) {
      s = 'ZBA-$s';
    }
    return s;
  }

  /// Parse a typed code, `ziba://pay/ZBA-…` URI, or JSON `{kind:ziba_pay,…}`.
  static ZibaPayPayload? parse(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;

    if (t.startsWith('{')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map) {
          final code = decoded['code']?.toString();
          if (code == null || code.isEmpty) return null;
          final normalized = normalize(code);
          if (!_codeRe.hasMatch(normalized)) return null;
          final amount = decoded['amount']?.toString();
          return ZibaPayPayload(
            code: normalized,
            amount: (amount != null && amount.isNotEmpty) ? amount : null,
            uri: decoded['uri']?.toString() ?? 'ziba://pay/$normalized',
          );
        }
      } catch (_) {
        return null;
      }
      return null;
    }

    final normalized = normalize(t);
    if (!_codeRe.hasMatch(normalized)) return null;
    return ZibaPayPayload(code: normalized, uri: 'ziba://pay/$normalized');
  }

  /// Confirm amount (from the code or the payer) into a pay intent.
  static PayIntent apply({
    required ZibaPayPayload payload,
    String? enteredAmount,
  }) {
    final amount = (payload.amount != null && payload.amount!.isNotEmpty)
        ? payload.amount!
        : (enteredAmount ?? '').trim();
    if (amount.isEmpty) {
      throw const FormatException('Enter an amount to pay.');
    }
    if (!RegExp(r'^\d+(\.\d{1,8})?$').hasMatch(amount)) {
      throw const FormatException('Enter an amount like 0.05 (up to 8 decimals).');
    }
    if (amount == '0' || amount == '0.0' || RegExp(r'^0+(\.0+)?$').hasMatch(amount)) {
      throw const FormatException('Enter an amount greater than zero.');
    }
    if (payload.amount != null &&
        payload.amount!.isNotEmpty &&
        enteredAmount != null &&
        enteredAmount.trim().isNotEmpty &&
        enteredAmount.trim() != payload.amount) {
      throw FormatException('This code is for a fixed amount. Send ${payload.amount} ZBA.');
    }
    return PayIntent(code: payload.code, amount: amount);
  }
}
