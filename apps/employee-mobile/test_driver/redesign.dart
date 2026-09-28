import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot:
      (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final dir = Directory('../../docs/evidence/redesign');
        await dir.create(recursive: true);
        await File('${dir.path}/$name.png').writeAsBytes(bytes);
        return true;
      },
);
