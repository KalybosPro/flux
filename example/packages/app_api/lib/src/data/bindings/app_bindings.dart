import 'package:app_api/src/data/apis/users_api.dart';
import 'package:app_api/src/data/controllers/users_controller.dart';
import 'package:app_api/src/data/repos/users_repo.dart';
import 'package:get/get.dart';
import '../apis/auth_api.dart';
import '../apis/recipes_api.dart';
import '../repos/auth_repo.dart';
import '../repos/recipes_repo.dart';
import '../controllers/auth_controller.dart';
import '../controllers/recipes_controller.dart';
import '../../di/di_container.dart' as di;

class AppBindings extends Bindings {
  AppBindings();

  @override
  void dependencies() {
    Get.lazyPut(() => UsersApi(appBaseUrl: di.appBaseUrl));
    Get.lazyPut(() => UsersRepo(api: Get.find()));
    Get.lazyPut(() => UsersController(repo: Get.find()));

    Get.lazyPut<AuthApi>(() => AuthApi(appBaseUrl: ''));
    Get.lazyPut<RecipesApi>(() => RecipesApi(appBaseUrl: ''));

    Get.lazyPut<AuthRepo>(() => AuthRepo(api: Get.find<AuthApi>()));
    Get.lazyPut<RecipesRepo>(() => RecipesRepo(api: Get.find<RecipesApi>()));

    Get.lazyPut<AuthController>(
      () => AuthController(repo: Get.find<AuthRepo>()),
    );
    Get.lazyPut<RecipesController>(
      () => RecipesController(repo: Get.find<RecipesRepo>()),
    );
  }
}
