import 'package:flugx_cli/flugx.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:path/path.dart' as p;
// Your file that does generation

void main() {
  group('Flux Generator', () {
    test('should generate expected folder structure', () async {
      final tempDir = Directory.systemTemp.createTempSync('flux_test_');
      final generator = FluxGenerator();

      try {
        // Run the generator
        await generator.generate(
            'test/assets/minimal_swagger.json', tempDir.path);

        // Check if the expected directories and files exist
        expect(Directory(p.join(tempDir.path, 'lib')).existsSync(), isTrue);
        expect(
            File(p.join(tempDir.path, 'lib', 'api.dart')).existsSync(), isTrue);
        expect(Directory(p.join(tempDir.path, 'lib', 'models')).existsSync(),
            isTrue);
        expect(
            Directory(p.join(tempDir.path, 'lib', 'controllers')).existsSync(),
            isTrue);
        expect(File(p.join(tempDir.path, 'pubspec.yaml')).existsSync(), isTrue);
      } finally {
        // Clean up
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should handle URL swagger files', () async {
      final tempDir = Directory.systemTemp.createTempSync('flux_test_url_');
      final generator = FluxGenerator();

      try {
        // Run the generator with a URL
        await generator.generate(
            'https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.yaml',
            tempDir.path);

        // Check if the expected directories and files exist
        expect(Directory(p.join(tempDir.path, 'lib')).existsSync(), isTrue);
        expect(
            File(p.join(tempDir.path, 'lib', 'api.dart')).existsSync(), isTrue);
        expect(Directory(p.join(tempDir.path, 'lib', 'models')).existsSync(),
            isTrue);
        expect(
            Directory(p.join(tempDir.path, 'lib', 'controllers')).existsSync(),
            isTrue);
        expect(File(p.join(tempDir.path, 'pubspec.yaml')).existsSync(), isTrue);
      } finally {
        // Clean up
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
