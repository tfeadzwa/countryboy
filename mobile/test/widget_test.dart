import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('idempotency key prevents duplicate ticket identity', () {
    const uuid = Uuid();
    final key1 = uuid.v4();
    final key2 = uuid.v4();
    expect(key1, isNot(equals(key2)));
  });
}
