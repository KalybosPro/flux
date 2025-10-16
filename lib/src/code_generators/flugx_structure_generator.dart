import 'package:flugx_cli/flugx.dart';
import 'package:universal_io/io.dart';

/// A functional code generator for creating Flutter GetX structures from OpenAPI specs.
/// Generates models, APIs, repositories, controllers, and bindings in a maintainable way.
class FluxStructureGenerator {
  final String outputDir;
  final List<String> models;
  final List<String> apis;
  final List<String> repos;
  final List<String> controllers;

  FluxStructureGenerator(this.outputDir)
      : models = [],
        apis = [],
        repos = [],
        controllers = [];

  Future<void> generateAll(Map<String, dynamic> swaggerDoc) async {
    // Generate models from components/schemas
    if (swaggerDoc['components']?['schemas'] != null) {
      await _generateModels(swaggerDoc['components']['schemas']);
    }

    // Generate APIs, Repos, Controllers from paths
    if (swaggerDoc['paths'] != null) {
      await _generateServices(swaggerDoc['paths']);
    }

    // Generate bindings
    await _generateBindings();

    // Generate export files
    await _generateExportFiles();
  }

  Future<void> _generateModels(Map<String, dynamic> schemas) async {
    for (final entry in schemas.entries) {
      final modelName = entry.key.snakeCase;
      final schema = entry.value as Map<String, dynamic>;

      models.add(modelName);
      await _generateModel(modelName, schema);
    }
  }

  Future<void> _generateModel(
      String modelName, Map<String, dynamic> schema) async {
    final properties = schema['properties'] as Map<String, dynamic>? ?? {};
    final required = (schema['required'] as List?)?.cast<String>() ?? [];

    final modelProps = generateModelProperties(properties, required);
    final constructorParams = generateConstructorParameters(properties, required);

    final buffer = StringBuffer();

    buffer.writeln(kServiceHeader);
    buffer.writeln();
    buffer.writeln("import 'package:app_api/app_api.dart';");
    buffer.writeln("import 'package:json_annotation/json_annotation.dart';");
    buffer.writeln();
    buffer.writeln("part '${modelName.toLowerCase()}.g.dart';");
    buffer.writeln();
    buffer.writeln('@JsonSerializable()');
    buffer.writeln('class ${modelName.pascalCase} {');

    // Properties
    for (final prop in modelProps) {
      buffer.writeln(prop);
    }

    // Constructor
    buffer.writeln('  const ${modelName.pascalCase}({');
    for (final param in constructorParams) {
      buffer.writeln(param);
    }
    buffer.writeln('  });');
    buffer.writeln();

    // JSON methods
    buffer.writeln(
        '  factory ${modelName.pascalCase}.fromJson(Map<String, dynamic> json) =>');
    buffer.writeln('      _\$${modelName.pascalCase}FromJson(json);');
    buffer.writeln();
    buffer.writeln(
        '  Map<String, dynamic> toJson() => _\$${modelName.pascalCase}ToJson(this);');
    buffer.writeln('}');

    await File(
            '$outputDir/lib/src/models/${modelName.toLowerCase().snakeCase}.dart')
        .writeAsString(buffer.toString());
  }

  /// Generates Dart properties from OpenAPI schema.
  static List<String> generateModelProperties(
      Map<String, dynamic> properties, List<String> required) {
    return properties.entries.map((prop) {
      final propName = prop.key.camelCase;
      final propType = getDartType(prop.value);
      final isRequired = required.contains(prop.key);
      final nullableModifier = isRequired ? '' : '?';
      final jsonKeyAnnotation = isRequired
          ? ''
          : '  @JsonKey(includeIfNull: false)\n';

      return '$jsonKeyAnnotation  final $propType$nullableModifier $propName;';
    }).toList();
  }

  /// Generates constructor parameters from OpenAPI schema.
  static List<String> generateConstructorParameters(
      Map<String, dynamic> properties, List<String> required) {
    return properties.entries.map((prop) {
      final propName = prop.key.camelCase;
      final isRequired = required.contains(prop.key);
      return '    ${isRequired ? 'required ' : ''}this.$propName,';
    }).toList();
  }

  /// Maps OpenAPI property types to Dart type strings.
  static String getDartType(Map<String, dynamic> property) {
    final type = property['type'] as String?;
    final format = property['format'] as String?;

    switch (type) {
      case 'string':
        if (format == 'date-time') return 'DateTime';
        return 'String';
      case 'integer':
        return 'int';
      case 'number':
        return 'double';
      case 'boolean':
        return 'bool';
      case 'array':
        final items = property['items'] as Map<String, dynamic>?;
        if (items != null) {
          final itemType = getDartType(items);
          return 'List<$itemType>';
        }
        return 'List<dynamic>';
      case 'object':
        return 'Map<String, dynamic>';
      default:
        // Check for reference
        if (property['\$ref'] != null) {
          final ref = property['\$ref'] as String;
          return ref.split('/').last.pascalCase;
        }
        return 'dynamic';
    }
  }

  /// Groups endpoints by service names and generates API, repository, and controller services.
  Future<void> _generateServices(Map<String, dynamic> paths) async {
    final serviceGroups = _groupEndpointsByService(paths);

    for (final group in serviceGroups.entries) {
      final serviceName = group.key.pascalCase;
      await _generateApiService(serviceName, group.value);
      await _generateRepository(serviceName, group.value);
      await _generateController(serviceName, group.value);

      apis.add(serviceName);
      repos.add(serviceName);
      controllers.add(serviceName);
    }
  }

  /// Groups endpoints from paths by service names based on tags or path segments.
  Map<String, List<Map<String, dynamic>>> _groupEndpointsByService(Map<String, dynamic> paths) {
    final serviceGroups = <String, List<Map<String, dynamic>>>{};

    for (final pathEntry in paths.entries) {
      final pathName = pathEntry.key;
      final pathMethods = pathEntry.value as Map<String, dynamic>;

      for (final methodEntry in pathMethods.entries) {
        final method = methodEntry.key;
        final operation = methodEntry.value as Map<String, dynamic>;

        final tags = (operation['tags'] as List?)?.cast<String>() ?? [];
        final serviceName =
            tags.isNotEmpty ? tags.first : _extractServiceFromPath(pathName);

        serviceGroups.putIfAbsent(serviceName, () => []).add({
          'path': pathName,
          'method': method,
          'operation': operation,
        });
      }
    }

    return serviceGroups;
  }

  String _extractServiceFromPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.first : 'default';
  }

  Future<void> _generateApiService(
      String serviceName, List<Map<String, dynamic>> endpoints) async {
    final className = '${serviceName}Api';
    final buffer = StringBuffer();

    buffer.writeln(kServiceHeader);
    buffer.writeln();
    buffer.writeln("import 'package:get/get.dart';");
    buffer.writeln();
    buffer.writeln(
        'class $className extends GetConnect implements GetxService {');
    buffer.writeln('  final String appBaseUrl;');
    buffer.writeln();
    buffer.writeln('  $className({required this.appBaseUrl}) {');
    buffer.writeln('    baseUrl = appBaseUrl;');
    buffer.writeln('    timeout = const Duration(seconds: 30);');
    buffer.writeln('  }');
    buffer.writeln();

    for (final endpoint in endpoints) {
      final method = endpoint['method'] as String;
      final path = endpoint['path'] as String;
      final operation = endpoint['operation'] as Map<String, dynamic>;
      final operationId = getOperationName(operation) ??
          '$method${path.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

      buffer.writeln('  Future<Response> ${operationId.camelCase}(');

      // Add path parameters
      final pathParams = extractPathParameters(path);
      for (final param in pathParams) {
        buffer.writeln('    String $param,');
      }

      // Add query parameters
      buffer.writeln('    {Map<String, dynamic>? queryParams,');
      if (method.toLowerCase() == 'post' || method.toLowerCase() == 'put') {
        buffer.writeln('    Map<String, dynamic>? body,');
      }
      buffer.writeln('  }) async {');
      buffer.writeln('    try {');

      // Build URL
      var urlPath = path;
      for (final param in pathParams) {
        urlPath = urlPath.replaceAll('{$param}', '\$$param');
      }
      buffer.writeln('      final url = "$urlPath";');

      // Make request
      switch (method.toLowerCase()) {
        case 'get':
          buffer.writeln(
              '      final response = await get(url, query: queryParams);');
          break;
        case 'post':
          buffer.writeln(
              '      final response = await post(url, body, query: queryParams);');
          break;
        case 'put':
          buffer.writeln(
              '      final response = await put(url, body, query: queryParams);');
          break;
        case 'delete':
          buffer.writeln(
              '      final response = await delete(url, query: queryParams);');
          break;
      }

      buffer.writeln('      return response;');
      buffer.writeln('    } on Response catch (e) {');
      buffer.writeln('      return e;');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('}');

    await File(
            '$outputDir/lib/src/data/apis/${serviceName.toLowerCase()}_api.dart')
        .writeAsString(buffer.toString());
  }

  /// Extracts operation name from OpenAPI operation, preferring operationId or deriving from summary.
  static String? getOperationName(Map<String, dynamic> operation) {
    String operationId = operation['operationId']?.toString() ?? '';
    String summary = operation['summary']?.toString() ?? '';

    operationId = removeDiacritics(operationId);
    summary = removeDiacritics(summary);

    // Check if operationId looks like a hash (32 hexadecimal characters)
    final isHash = RegExp(r'^[a-f0-9]{32}$').hasMatch(operationId);

    if ((operationId.isEmpty || isHash) && summary.isNotEmpty) {
      final words = summary.split(RegExp(r'[\s_-]+'));
      if (words.length >= 2) {
        final first = words.first.toLowerCase();
        final last = words.last.toLowerCase();
        return '$first${capitalize(last)}';
      }
    }

    return operationId;
  }

  Future<void> _generateRepository(
      String serviceName, List<Map<String, dynamic>> endpoints) async {
    final className = '${serviceName}Repo';
    final apiClassName = '${serviceName}Api';
    final buffer = StringBuffer();

    buffer.writeln(kServiceHeader);
    buffer.writeln();
    buffer.writeln("import 'package:get/get.dart';");
    buffer.writeln("import '../apis/${serviceName.toLowerCase()}_api.dart';");
    buffer.writeln();
    buffer.writeln('class $className extends GetxService {');
    buffer.writeln('  final $apiClassName api;');
    buffer.writeln();
    buffer.writeln('  $className({required this.api});');
    buffer.writeln();

    for (final endpoint in endpoints) {
      final method = endpoint['method'] as String;
      final path = endpoint['path'] as String;
      final operation = endpoint['operation'] as Map<String, dynamic>;
      final operationId = getOperationName(operation) ??
          '$method${path.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

      buffer.writeln('  Future<Response> ${operationId.camelCase}({');

      // Add path parameters
      final pathParams = extractPathParameters(path);
      for (final param in pathParams) {
        buffer.writeln('    required String $param,');
      }

      buffer.writeln('    Map<String, dynamic>? queryParams,');
      if (method.toLowerCase() == 'post' || method.toLowerCase() == 'put') {
        buffer.writeln('    Map<String, dynamic>? body,');
      }
      buffer.writeln('  }) async {');

      buffer.writeln('    return await api.${operationId.camelCase}(');
      for (final param in pathParams) {
        buffer.writeln('      $param,');
      }
      buffer.writeln('      queryParams: queryParams,');
      if (method.toLowerCase() == 'post' || method.toLowerCase() == 'put') {
        buffer.writeln('      body: body,');
      }
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('}');

    await File(
            '$outputDir/lib/src/data/repos/${serviceName.toLowerCase()}_repo.dart')
        .writeAsString(buffer.toString());
  }

  Future<void> _generateController(
      String serviceName, List<Map<String, dynamic>> endpoints) async {
    final className = '${serviceName}Controller';
    final repoClassName = '${serviceName}Repo';
    final buffer = StringBuffer();

    buffer.writeln(kServiceHeader);
    buffer.writeln();
    buffer.writeln("import 'dart:convert';");
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:get/get.dart';");
    buffer.writeln("import '../repos/${serviceName.toLowerCase()}_repo.dart';");

    // Import models if they exist
    if (models.isNotEmpty) {
      buffer.writeln("import '../../models/models.dart';");
    }

    buffer.writeln();
    buffer.writeln('class $className extends GetxController {');
    buffer.writeln('  final $repoClassName repo;');
    buffer.writeln();
    buffer.writeln('  $className({required this.repo});');
    buffer.writeln();

    // Add common reactive variables
    buffer.writeln('  final RxBool isLoading = false.obs;');
    buffer.writeln('  final Rx<String?> error = Rx<String?>(null);');
    buffer.writeln('  final RxList<dynamic> items = <dynamic>[].obs;');
    buffer.writeln();

    for (final endpoint in endpoints) {
      final method = endpoint['method'] as String;
      final path = endpoint['path'] as String;
      final operation = endpoint['operation'] as Map<String, dynamic>;
      final operationId = getOperationName(operation) ??
          '$method${path.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

      buffer.writeln('  Future<void> ${operationId.camelCase}({');

      // Add path parameters
      final pathParams = extractPathParameters(path);
      for (final param in pathParams) {
        buffer.writeln('    required String $param,');
      }

      buffer.writeln('    Map<String, dynamic>? queryParams,');
      if (method.toLowerCase() == 'post' || method.toLowerCase() == 'put') {
        buffer.writeln('    Map<String, dynamic>? body,');
      }
      buffer.writeln('  }) async {');

      buffer.writeln('    try {');
      buffer.writeln('      isLoading.value = true;');
      buffer.writeln('      error.value = null;');
      buffer.writeln();
      buffer.writeln(
          '      final response = await repo.${operationId.camelCase}(');
      for (final param in pathParams) {
        buffer.writeln('        $param: $param,');
      }
      buffer.writeln('        queryParams: queryParams,');
      if (method.toLowerCase() == 'post' || method.toLowerCase() == 'put') {
        buffer.writeln('        body: body,');
      }
      buffer.writeln('      );');
      buffer.writeln();
      buffer.writeln('      if (response.isOk) {');
      buffer.writeln('        // Handle successful response');
      if (method.toLowerCase() == 'get') {
        buffer.writeln('        if (response.body is List) {');
        buffer.writeln('          items.value = response.body;');
        buffer.writeln('        } else if (response.body is Map) {');
        buffer.writeln('          items.clear();');
        buffer.writeln('          items.add(response.body);');
        buffer.writeln('        }');
      }
      buffer.writeln(
          '        debugPrint("$operationId success: \${response.statusCode}");');
      buffer.writeln('      } else {');
      buffer.writeln(
          '        error.value = "Request failed: \${response.statusCode} - \${response.statusText}";');
      buffer.writeln('        debugPrint(error.value);');
      buffer.writeln('      }');
      buffer.writeln('    } on Exception catch (e) {');
      buffer.writeln('      error.value = "Exception: \${e.toString()}";');
      buffer.writeln('      debugPrint(error.value);');
      buffer.writeln('    } finally {');
      buffer.writeln('      isLoading.value = false;');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('  @override');
    buffer.writeln('  void onInit() {');
    buffer.writeln('    super.onInit();');
    buffer.writeln('    // Initialize controller if needed');
    buffer.writeln('  }');
    buffer.writeln('}');

    await File(
            '$outputDir/lib/src/data/controllers/${serviceName.toLowerCase()}_controller.dart')
        .writeAsString(buffer.toString());
  }

  Future<void> _generateBindings() async {
    final buffer = StringBuffer();

    buffer.writeln("import 'package:get/get.dart';");

    // Import APIs
    for (final api in apis) {
      buffer.writeln("import '../apis/${api.toLowerCase()}_api.dart';");
    }

    // Import Repos
    for (final repo in repos) {
      buffer.writeln("import '../repos/${repo.toLowerCase()}_repo.dart';");
    }

    // Import Controllers
    for (final controller in controllers) {
      buffer.writeln(
          "import '../controllers/${controller.toLowerCase()}_controller.dart';");
    }

    buffer.writeln();
    buffer.writeln('class AppBindings extends Bindings {');
    buffer.writeln('  final String appBaseUrl;');
    buffer.writeln();
    buffer.writeln('  AppBindings({required this.appBaseUrl});');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void dependencies() {');

    // Bind APIs
    for (final api in apis) {
      buffer.writeln(
          '    Get.lazyPut<${api}Api>(() => ${api}Api(appBaseUrl: appBaseUrl));');
    }
    buffer.writeln();

    // Bind Repos
    for (int i = 0; i < repos.length; i++) {
      final repo = repos[i];
      final api = apis[i];
      buffer.writeln(
          '    Get.lazyPut<${repo}Repo>(() => ${repo}Repo(api: Get.find<${api}Api>()));');
    }
    buffer.writeln();

    // Bind Controllers
    for (int i = 0; i < controllers.length; i++) {
      final controller = controllers[i];
      final repo = repos[i];
      buffer.writeln(
          '    Get.lazyPut<${controller}Controller>(() => ${controller}Controller(repo: Get.find<${repo}Repo>()));');
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    await File('$outputDir/lib/src/data/bindings/app_bindings.dart')
        .writeAsString(buffer.toString());
  }

  /// Generates export files for models, APIs, repos, and controllers.
  Future<void> _generateExportFiles() async {
    // Helper function to generate export content
    String generateExports(List<String> items, String suffix) {
      final buffer = StringBuffer();
      for (final item in items) {
        buffer.writeln("export '${item.toLowerCase()}$suffix");
      }
      return buffer.toString();
    }

    // Generate model exports
    if (models.isNotEmpty) {
      await File('$outputDir/lib/src/models/models.dart')
          .writeAsString(generateExports(models, '.dart'));
    }

    // Generate API exports
    if (apis.isNotEmpty) {
      await File('$outputDir/lib/src/data/apis/apis.dart')
          .writeAsString(generateExports(apis, '_api.dart'));
    }

    // Generate repository exports
    if (repos.isNotEmpty) {
      await File('$outputDir/lib/src/data/repos/repos.dart')
          .writeAsString(generateExports(repos, '_repo.dart'));
    }

    // Generate controller exports
    if (controllers.isNotEmpty) {
      await File('$outputDir/lib/src/data/controllers/controllers.dart')
          .writeAsString(generateExports(controllers, '_controller.dart'));
    }
  }
}
