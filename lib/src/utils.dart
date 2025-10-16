import 'package:universal_io/io.dart';

/// Ensures that a directory exists, creating it recursively if necessary.
Future<void> ensureDirExists(Directory dir) async {
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

/// Removes diacritics (accents) from a string, converting them to their base characters.
/// Useful for generating clean identifiers from potentially accented text.
String removeDiacritics(String input) {
  const accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
    'À': 'A',
    'Á': 'A',
    'Â': 'A',
    'Ä': 'A',
    'Ç': 'C',
    'È': 'E',
    'É': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Î': 'I',
    'Ï': 'I',
    'Ô': 'O',
    'Ö': 'O',
    'Ù': 'U',
    'Ú': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ÿ': 'Y',
  };

  return input.split('').map((char) => accents[char] ?? char).join();
}

/// Capitalizes the first letter of a string, leaving the rest unchanged.
String capitalize(String word) {
  if (word.isEmpty) return '';
  return word[0].toUpperCase() + word.substring(1);
}

/// Extracts path parameters from a URL path string.
/// Parameters are identified by curly braces, e.g., "/users/{id}" would return ["id"].
List<String> extractPathParameters(String path) {
  final regex = RegExp(r'\{([^}]+)\}');
  return regex.allMatches(path).map((m) => m.group(1)!).toList();
}
