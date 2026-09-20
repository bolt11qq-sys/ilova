/// Identifier helpers. The demo never talks to a server, so a local RFC-4122
/// version-4 generator is enough (no `uuid` package — see DECISIONS.md).
library;

import 'dart:math';

final Random _rnd = Random.secure();

String uuid() {
  final b = List<int>.generate(16, (_) => _rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 1
  String hex(int from, int to) => b
      .sublist(from, to)
      .map((x) => x.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// Short, sortable-ish id used for shop and custom-product ids (`n-lz4k9`).
String shortId(String prefix) =>
    '$prefix${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
