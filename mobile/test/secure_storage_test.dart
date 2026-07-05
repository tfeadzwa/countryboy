import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Offline PIN verification hash', () {
    String hashPin(String pin, String merchant, String agent) {
      final payload = '${merchant.toUpperCase()}:${agent.toUpperCase()}:$pin';
      return sha256.convert(utf8.encode(payload)).toString();
    }

    test('matching credentials produce same hash', () {
      expect(
        hashPin('1234', 'HRE001', 'TMO014'),
        hashPin('1234', 'HRE001', 'TMO014'),
      );
    });

    test('wrong pin produces different hash', () {
      expect(
        hashPin('1234', 'HRE001', 'TMO014'),
        isNot(hashPin('9999', 'HRE001', 'TMO014')),
      );
    });
  });

  group('Idempotency', () {
    test('unique keys are generated for each ticket attempt', () {
      const uuid = Uuid();
      final keys = List.generate(10, (_) => uuid.v4());
      expect(keys.toSet().length, keys.length);
    });
  });
}
