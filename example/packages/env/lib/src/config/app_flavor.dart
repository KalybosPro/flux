import 'package:env/env.dart';

enum Flavor { production }

sealed class AppEnv {
  const AppEnv();

  String getEnv(Env env);
}

class AppFlavor extends AppEnv {
  factory AppFlavor.production() =>
      const AppFlavor._(flavor: Flavor.production);

  const AppFlavor._({required this.flavor});

  final Flavor flavor;

  @override
  String getEnv(Env env) => switch (env) {
    Env.baseUrl => switch (flavor) {
      Flavor.production => EnvProd.baseUrl,
    },

    Env.resultsUrl => switch (flavor) {
      Flavor.production => EnvProd.resultsUrl,
    },
  };
}
