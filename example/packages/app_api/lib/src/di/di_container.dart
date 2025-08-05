import 'package:env/env.dart';

final _appFlavor = AppFlavor.production();

final appBaseUrl = _appFlavor.getEnv(Env.baseUrl);

final resultsUrl = _appFlavor.getEnv(Env.resultsUrl);
