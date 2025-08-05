import 'package:universal_io/io.dart';

Future<void> ensureDirExists(Directory dir) async {
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

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

String capitalize(String word) {
  if (word.isEmpty) return '';
  return word[0].toUpperCase() + word.substring(1);
}

List<String> extractPathParameters(String path) {
  final regex = RegExp(r'\{([^}]+)\}');
  return regex.allMatches(path).map((m) => m.group(1)!).toList();
}
