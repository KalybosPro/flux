#!/usr/bin/env dart
// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:args/args.dart';
import 'package:flux/flux.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('swagger', abbr: 's', help: 'Path to swagger file or URL')
    ..addFlag('help',
        abbr: 'h', help: 'Show usage information', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool || results['swagger'] == null) {
      print('Flux CLI - Flutter API Package Generator');
      print('Usage: flux --swagger <path_or_url>');
      print(parser.usage);
      return;
    }

    final generator = FluxGenerator();

    final currentDir = Directory.current.path;
    // Ensure packages folder exists
    final packagesDir = Directory(p.join(currentDir, packagesPath));
    try {
      print('Creating packages directory...');
      await ensureDirExists(packagesDir);
    } catch (e) {
      print('Error creating packages directory at ${packagesDir.path}: $e');
      exit(1);
    }

    // Create or find app_api package directory
    final appApiPackageDir =
        Directory(p.join(packagesDir.path, apiPackagePath));
    try {
      await ensureDirExists(appApiPackageDir);
      print('Creating app_api Flutter package...');
      await generator.runProcess('flutter',
          ['create', '--template=package', '$packagesPath/$apiPackagePath'],
          workingDirectory: currentDir);
    } catch (e) {
      print(
          'Error creating app_api package directory at ${appApiPackageDir.path}: $e');
      exit(1);
    }

    final swaggerPath = results['swagger'] as String;
    final outputDir = appApiPackageDir.path;

    print('Generating Flutter API package with Flux...');
    print('Swagger: $swaggerPath');
    print('Output: $outputDir');

    await generator.generate(swaggerPath, outputDir);

    print('Generating models json serializations...');
    await generator.runProcess('dart',
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        workingDirectory: appApiPackageDir.path);

    print('Package generated successfully!');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
