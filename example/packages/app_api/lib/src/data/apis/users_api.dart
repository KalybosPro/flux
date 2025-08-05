import 'package:get/get.dart';

class UsersApi extends GetConnect implements GetxService {
  final String appBaseUrl;
  UsersApi({required this.appBaseUrl}) {
    baseUrl = appBaseUrl;
    timeout = const Duration(seconds: 30);
  }

  Future<Response> getProduct(String url) async {
    try {
      final response = await get(url);
      return response;
    } on Response catch (e) {
      return e;
    }
  }
}
