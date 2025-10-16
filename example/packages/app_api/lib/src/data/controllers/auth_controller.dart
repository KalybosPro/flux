// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repos/auth_repo.dart';

class AuthController extends GetxController {
  final AuthRepo repo;

  AuthController({required this.repo});

  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final RxList<dynamic> items = <dynamic>[].obs;

  Future<void> registerUser({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await repo.registerUser(
        queryParams: queryParams,
        body: body,
      );

      if (response.isOk) {
        // Handle successful response
        debugPrint("registerUser success: ${response.statusCode}");
      } else {
        error.value =
            "Request failed: ${response.statusCode} - ${response.statusText}";
        debugPrint(error.value);
      }
    } on Exception catch (e) {
      error.value = "Exception: ${e.toString()}";
      debugPrint(error.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> userLogin({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await repo.userLogin(
        queryParams: queryParams,
        body: body,
      );

      if (response.isOk) {
        // Handle successful response
        debugPrint("userLogin success: ${response.statusCode}");
      } else {
        error.value =
            "Request failed: ${response.statusCode} - ${response.statusText}";
        debugPrint(error.value);
      }
    } on Exception catch (e) {
      error.value = "Exception: ${e.toString()}";
      debugPrint(error.value);
    } finally {
      isLoading.value = false;
    }
  }

}
