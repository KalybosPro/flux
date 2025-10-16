// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repos/recipes_repo.dart';

class RecipesController extends GetxController {
  final RecipesRepo repo;

  RecipesController({required this.repo});

  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final RxList<dynamic> items = <dynamic>[].obs;

  Future<void> getFilters({Map<String, dynamic>? queryParams}) async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await repo.getFilters(queryParams: queryParams);

      if (response.isOk) {
        // Handle successful response
        if (response.body is List) {
          items.value = response.body;
        } else if (response.body is Map) {
          items.clear();
          items.add(response.body);
        }
        debugPrint("getFilters success: ${response.statusCode}");
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

  Future<void> createOnly({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await repo.createOnly(
        queryParams: queryParams,
        body: body,
      );

      if (response.isOk) {
        // Handle successful response
        debugPrint("createOnly) success: ${response.statusCode}");
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

  Future<void> getId({
    required String id,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await repo.getId(id: id, queryParams: queryParams);

      if (response.isOk) {
        // Handle successful response
        if (response.body is List) {
          items.value = response.body;
        } else if (response.body is Map) {
          items.clear();
          items.add(response.body);
        }
        debugPrint("getId success: ${response.statusCode}");
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

  Future<void> updateOnly({
    required String id,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await repo.updateOnly(
        id: id,
        queryParams: queryParams,
        body: body,
      );

      if (response.isOk) {
        // Handle successful response
        debugPrint("updateOnly) success: ${response.statusCode}");
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

  Future<void> deleteOnly({
    required String id,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await repo.deleteOnly(id: id, queryParams: queryParams);

      if (response.isOk) {
        // Handle successful response
        debugPrint("deleteOnly) success: ${response.statusCode}");
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
