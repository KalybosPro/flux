import 'dart:convert';

import 'package:app_api/src/data/repos/users_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class UsersController extends GetxController {
  final UsersRepo repo;
  UsersController({required this.repo});

  final ScrollController scrollController = ScrollController();

  final RxBool isGetUser = false.obs;
  final RxBool isLoading = false.obs;

  final RxList users = RxList();

  final RxInt limit = 40.obs;

  Future getProduct() async {
    try {
      isGetUser.value = true;
      Response response = await repo.getProduct(limit: limit.value);
      if (response.isOk) {
        users.value = response.body['results'];
      } else {
        debugPrint(
          'Request failed with: ${response.statusCode}, ${response.statusText}',
        );
      }
    } on Exception catch (e) {
      debugPrint('Exception: ${e.toString()}');
    } finally {
      isGetUser.value = false;
    }
  }

  Future<void> _loadMore() async {
    try {
      if (isLoading.value) return;
      isLoading.value = true;
      limit.value += 20;
      Response response = await repo.getProduct(limit: limit.value);
      if (response.isOk) {
        users.value += response.body['results'];
      }
    } on Exception catch (e) {
      debugPrint('Exception on load more: ${e.toString()}');
    } finally {
      Future.delayed(const Duration(seconds: 1));
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    getProduct();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
    fetchData();
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// =======================================

  Future<void> fetchData() async {
    const swaggerPath =
        "D:/src/projects/apps/servers/culinaire_backend/swagger.json";

    try {
      final jsonString = await rootBundle.loadString(swaggerPath);
      final jsonData = json.decode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        if (kDebugMode) {
          print('OpenAPI Title: ${jsonData['info']['title']}');
        }
        if (kDebugMode) {
          print('Nombre de routes: ${jsonData['paths'].keys.length}');
        }
        // return jsonData;
      } else {
        throw Exception('Le fichier JSON n’est pas valide');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }
}
