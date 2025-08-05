import 'package:envied/envied.dart';

part 'env.prod.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class EnvProd {
  /// The value for Base Url.
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _EnvProd.baseUrl;

  /// The value for Results Url.
  @EnviedField(varName: 'RESULTS_URL', obfuscate: true)
  static final String resultsUrl = _EnvProd.resultsUrl;
}
