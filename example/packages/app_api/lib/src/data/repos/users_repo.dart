import 'package:app_api/src/data/apis/users_api.dart';
import 'package:get/get.dart';
import '../../di/di_container.dart' as di;

class UsersRepo extends GetxService {
  final UsersApi api;
  UsersRepo({required this.api});

  Future<Response> getProduct({int limit = 40}) async {
    final url = "${di.resultsUrl}$limit";
    return await api.getProduct(url);
  }
}
