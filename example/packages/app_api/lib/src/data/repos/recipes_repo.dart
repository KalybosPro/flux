// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:get/get.dart';
import '../apis/recipes_api.dart';

class RecipesRepo extends GetxService {
  final RecipesApi api;

  RecipesRepo({required this.api});

  Future<Response> getFilters({Map<String, dynamic>? queryParams}) async {
    return await api.getFilters(queryParams: queryParams);
  }

  Future<Response> createOnly({
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    return await api.createOnly(queryParams: queryParams, body: body);
  }

  Future<Response> getId({
    required String id,
    Map<String, dynamic>? queryParams,
  }) async {
    return await api.getId(id, queryParams: queryParams);
  }

  Future<Response> updateOnly({
    required String id,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    return await api.updateOnly(id, queryParams: queryParams, body: body);
  }

  Future<Response> deleteOnly({
    required String id,
    Map<String, dynamic>? queryParams,
  }) async {
    return await api.deleteOnly(id, queryParams: queryParams);
  }
}
