import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:universal_io/io.dart';

import 'code_generators/flux_structure_generator.dart';

class FluxGenerator {
  Future<void> generate(String swaggerPath, String outputDir) async {
    // Create output directory structure
    await _createDirectoryStructure(outputDir);

    // Read swagger content
    String swaggerContent;
    if (swaggerPath.startsWith('http')) {
      swaggerContent = await _fetchSwaggerFromUrl(swaggerPath);
    } else {
      swaggerContent = await File(swaggerPath).readAsString();
    }

    // Parse swagger
    dynamic swaggerDoc;

    if (swaggerPath.startsWith('http')) {
      swaggerDoc =
          loadYaml(swaggerContent, sourceUrl: Uri.tryParse(swaggerPath));
    } else {
      swaggerDoc = loadYaml(swaggerContent);
    }

    final dartMap = convertYamlToMap(swaggerDoc);

    // Generate models with json_annotation
    final structureGenerator = FluxStructureGenerator(outputDir);
    await structureGenerator.generateAll(Map<String, dynamic>.from(dartMap));

    // Create pubspec.yaml
    await _createPubspec(outputDir);

    // Create main export file
    await _createMainExportFile(outputDir);
  }

  // bool isSwaggerJson(File file) {
  //   try {
  //     final content = file.readAsStringSync();
  //     final json = jsonDecode(content);

  //     // Verify typic keys of Swagger/OpenAPI file
  //     final hasOpenApiKey =
  //         json.containsKey('openapi') || json.containsKey('swagger');
  //     final hasInfo = json.containsKey('info');
  //     final hasPaths = json.containsKey('paths');

  //     return hasOpenApiKey && hasInfo && hasPaths;
  //   } catch (e) {
  //     print('Erreur lors de la lecture ou du parsing du fichier : $e');
  //     return false;
  //   }
  // }

  Map<String, dynamic> convertYamlToMap(YamlMap yamlMap) {
    final map = <String, dynamic>{};
    yamlMap.forEach((key, value) {
      if (value is YamlMap) {
        map[key.toString()] = convertYamlToMap(value);
      } else {
        map[key.toString()] = value;
      }
    });

    return map;
  }

  Future<String> _fetchSwaggerFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(
          'Failed to fetch swagger from URL: ${response.statusCode}');
    }
  }

  Future<void> runProcess(String executable, List<String> arguments,
      {required String workingDirectory}) async {
    final proc = await Process.start(
      executable,
      arguments,
      runInShell: true,
      workingDirectory: workingDirectory,
    );
    await stdout.addStream(proc.stdout);
    await stderr.addStream(proc.stderr);
    final exitCode = await proc.exitCode;
    if (exitCode != 0) {
      stderr.write(proc.stderr);
      print('Failed to create Flutter package:');
      exit(1);
    }
  }

  Future<void> _createDirectoryStructure(String outputDir) async {
    final dirs = [
      '$outputDir/lib',
      '$outputDir/lib/src/models',
      '$outputDir/lib/src/data/apis',
      '$outputDir/lib/src/data/repos',
      '$outputDir/lib/src/data/controllers',
      '$outputDir/lib/src/data/bindings',
    ];

    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }
  }

  Future<void> _createPubspec(String outputDir) async {
//     final pubspecContent = '''
// name: app_api
// description: Generated API package with Flux
// version: 1.0.0

// environment:
//   sdk: '>=3.0.0 <4.0.0'
//   flutter: ">=3.0.0"

// dependencies:
//   flutter:
//     sdk: flutter
//   get: ^4.6.5
//   json_annotation: ^4.8.1
//   http: ^1.1.0

// dev_dependencies:
//   flutter_test:
//     sdk: flutter
//   build_runner: ^2.4.7
//   json_serializable: ^6.7.1
//   flutter_lints: ^3.0.0

// flutter:
// ''';

//     await File('$outputDir/pubspec.yaml').writeAsString(pubspecContent);

    print('GetX package installation...');
    await runProcess('flutter', ['pub', 'add', 'get'],
        workingDirectory: outputDir);
    print('json_annotation package installation...');
    await runProcess('flutter', ['pub', 'add', 'json_annotation'],
        workingDirectory: outputDir);
    print('build_runner package installation...');
    await runProcess('flutter', ['pub', 'add', 'build_runner', '--dev'],
        workingDirectory: outputDir);
    print('json_serializable package installation...');
    await runProcess('flutter', ['pub', 'add', 'json_serializable', '--dev'],
        workingDirectory: outputDir);
  }

  Future<void> _createMainExportFile(String outputDir) async {
    final exportContent = '''
library app_api;

// Models
export 'src/models/models.dart';

// APIs
export 'src/data/apis/apis.dart';

// Repositories
export 'src/data/repos/repos.dart';

// Controllers
export 'src/data/controllers/controllers.dart';

// Bindings
export 'src/data/bindings/app_bindings.dart';
''';

    await File('$outputDir/lib/app_api.dart').writeAsString(exportContent);
  }
}
