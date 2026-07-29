import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Token save/read/delete', () async {
    final storage = MemoryAuthTokenStorage();

    expect(await storage.hasAccessToken(), isFalse);

    await storage.saveAccessToken('jwt-token');

    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.readAccessToken(), 'jwt-token');

    await storage.deleteAccessToken();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.readAccessToken(), isNull);
  });
}
