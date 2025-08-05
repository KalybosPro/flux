// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:get/get.dart';

class AuthApi extends GetConnect implements GetxService {
  final String appBaseUrl;

  AuthApi({required this.appBaseUrl}) {
    baseUrl = appBaseUrl;
    timeout = const Duration(seconds: 30);
  }

  Future<Response> registerUser({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = "/auth/register";
      final response = await post(url, body, query: queryParams);
      return response;
    } on Response catch (e) {
      return e;
    }
  }

  Future<Response> userLogin({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = "/auth/login";
      final response = await post(url, body, query: queryParams);
      return response;
    } on Response catch (e) {
      return e;
    }
  }
}
