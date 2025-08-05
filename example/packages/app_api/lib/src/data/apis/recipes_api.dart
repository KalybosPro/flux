// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:get/get.dart';

class RecipesApi extends GetConnect implements GetxService {
  final String appBaseUrl;

  RecipesApi({required this.appBaseUrl}) {
    baseUrl = appBaseUrl;
    timeout = const Duration(seconds: 30);
  }

  Future<Response> getFilters({Map<String, dynamic>? queryParams}) async {
    try {
      final url = "/recipes";
      final response = await get(url, query: queryParams);
      return response;
    } on Response catch (e) {
      return e;
    }
  }

  Future<Response> createOnly({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = "/recipes";
      final response = await post(url, body, query: queryParams);
      return response;
    } on Response catch (e) {
      return e;
    }
  }

  Future<Response> getId(String id, {Map<String, dynamic>? queryParams}) async {
    try {
      final url = "/recipes/$id";
      final response = await get(url, query: queryParams);
      return response;
    } on Response catch (e) {
      return e;
    }
  }

  Future<Response> updateOnly(
    String id, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = "/recipes/$id";
      final response = await put(url, body, query: queryParams);
      return response;
    } on Response catch (e) {
      return e;
    }
  }

  Future<Response> deleteOnly(
    String id, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final url = "/recipes/$id";
      final response = await delete(url, query: queryParams);
      return response;
    } on Response catch (e) {
      return e;
    }
  }
}
