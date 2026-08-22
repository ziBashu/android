import 'package:flutter_test/flutter_test.dart';
import 'package:seru/core/pay_code.dart';

void main() {
  test('parses typed, URI, and JSON ZIBA pay codes and applies amount', () {
    final typed = ZibaPayCodes.parse('zba-ab2def');
    expect(typed, isNotNull);
    expect(typed!.code, 'ZBA-AB2DEF');

    final uri = ZibaPayCodes.parse('ziba://pay/ZBA-AB2DEF');
    expect(uri!.code, 'ZBA-AB2DEF');

    final json = ZibaPayCodes.parse(
      '{"v":1,"kind":"ziba_pay","code":"ZBA-AB2DEF","amount":"0.05"}',
    );
    expect(json!.code, 'ZBA-AB2DEF');
    expect(json.amount, '0.05');

    final intent = ZibaPayCodes.apply(payload: json);
    expect(intent.code, 'ZBA-AB2DEF');
    expect(intent.amount, '0.05');

    expect(ZibaPayCodes.parse('not-a-code'), isNull);
    expect(
      () => ZibaPayCodes.apply(payload: typed),
      throwsA(isA<FormatException>()),
    );
  });
}
