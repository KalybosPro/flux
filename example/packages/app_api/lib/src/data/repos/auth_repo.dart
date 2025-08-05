// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:get/get.dart';
import '../apis/auth_api.dart';

class AuthRepo extends GetxService {
  final AuthApi api;

  AuthRepo({required this.api});

  Future<Response> registerUser({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    return await api.registerUser(queryParams: queryParams, body: body);
  }

  Future<Response> userLogin({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    return await api.userLogin(queryParams: queryParams, body: body);
  }
}
