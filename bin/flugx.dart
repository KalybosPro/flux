#!/usr/bin/env dart
// Copyright (c) 2025 Flugx CLI. All rights reserved.
//
// This source code is part of Flugx CLI - Flutter API Package Generator.
// See LICENSE file for licensing information.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:flugx_cli/flugx.dart';
import 'package:path/path.dart' as p;

/// Flugx CLI entry point that generates Flutter API packages from OpenAPI specs.
/// Returns appropriate exit codes: 0 for success, 1 for errors.
Future<int> main(List<String> arguments) async {
  final parser = _createArgumentParser();

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool || results['swagger'] == null) {
      _printUsage(parser);
      return io.exitCode;
    }

    final generator = FluxGenerator();
    final projectRoot = io.Directory.current.path;

    // Initialize project structure
    final exitCode = await _initializeProjectStructure(generator, projectRoot);
    if (exitCode != 0) return exitCode;

    // Generate the API package
    final swaggerPath = results['swagger'] as String;
    final packagesDir = p.join(projectRoot, packagesPath);
    final outputDir = p.join(packagesDir, apiPackagePath);

    print('🚀 Generating Flutter API package with Flugx...');
    print('📄 Swagger spec: $swaggerPath');
    print('📁 Output directory: $outputDir');

    await generator.generate(swaggerPath, outputDir);

    // Generate JSON serialization code
    final buildExitCode = await _runBuildRunner(outputDir);
    if (buildExitCode != 0) return buildExitCode;

    print('✅ Package generated successfully!');
    print('📦 Add to pubspec.yaml: app_api:\n    path: packages/app_api');

    return 0;
  } on ArgParserException catch (e) {
    io.stderr.writeln('❌ Argument error: ${e.message}');
    _printUsage(parser);
    return 1;
  } catch (e, stackTrace) {
    io.stderr.writeln('💥 Unexpected error: $e');
    if (io.Platform.environment['DEBUG'] == 'true') {
      io.stderr.writeln(stackTrace);
    }
    return 1;
  }
}

/// Creates and configures the argument parser.
ArgParser _createArgumentParser() {
  return ArgParser()
    ..addOption(
      'swagger',
      abbr: 's',
      help: 'Path to OpenAPI/Swagger specification file or URL',
      mandatory: true,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Display usage information',
      negatable: false,
    );
}

/// Prints the CLI usage information.
void _printUsage(ArgParser parser) {
  print('Flugx CLI - Professional Flutter API Package Generator');
  print('');
  print('Generate production-ready Flutter packages from OpenAPI specs with GetX architecture.');
  print('');
  print('USAGE:');
  print('  flugx --swagger <path_or_url>');
  print('');
  print('EXAMPLES:');
  print('  flugx --swagger swagger.json');
  print('  flugx --swagger https://api.example.com/swagger.json');
  print('  flugx --help');
  print('');
  print('OPTIONS:');
  print(parser.usage);
}

/// Initializes the required project directory structure.
Future<int> _initializeProjectStructure(
  FluxGenerator generator,
  String projectRoot,
) async {
  try {
    // Ensure packages directory exists
    final packagesDir = io.Directory(p.join(projectRoot, packagesPath));
    await ensureDirExists(packagesDir);
    print('📁 Created packages directory');

    // Prepare app_api package directory
    final appApiPackageDir = io.Directory(p.join(packagesDir.path, apiPackagePath));
    await ensureDirExists(appApiPackageDir);
    print('📦 Prepared app_api package directory');

    // Create Flutter package structure
    final createExitCode = await _createFlutterPackage(generator, projectRoot);
    return createExitCode;
  } catch (e) {
    io.stderr.writeln('❌ Failed to initialize project structure: $e');
    return 1;
  }
}

/// Creates the Flutter package using flutter create.
Future<int> _createFlutterPackage(FluxGenerator generator, String projectRoot) async {
  try {
    print('🔨 Creating Flutter package...');
    final result = await generator.runProcess(
      'flutter',
      ['create', '--template=package', '$packagesPath/$apiPackagePath'],
      workingDirectory: projectRoot,
    );
    if(result.exitCode != 0) {
      io.stderr.writeln('❌ Flutter create failed: ${result.stderr}');
      return result.exitCode;
    }
    return result.exitCode; // Process.run throws on non-zero exit codes
  } catch (e) {
    io.stderr.writeln('❌ Failed to create Flutter package: $e');
    return 1;
  }
}

/// Runs build_runner to generate JSON serialization code.
Future<int> _runBuildRunner(String workingDirectory) async {
  try {
    final generator = FluxGenerator();
    print('🔧 Generating JSON serialization code...');
    await generator.runProcess(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: workingDirectory,
    );
    return 0;
  } catch (e) {
    io.stderr.writeln('❌ Failed to generate serialization code: $e');
    return 1;
  }
}
