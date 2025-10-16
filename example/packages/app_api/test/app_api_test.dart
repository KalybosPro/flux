import 'package:flutter_test/flutter_test.dart';

import 'package:app_api/app_api.dart';

void main() {
  test('adds one to input values', () {
    final recipesRepo = RecipesRepo(
      api: RecipesApi(appBaseUrl: 'http://example.com'),
    );

    expect(recipesRepo.getFilters(), isA<Future<Response>>());
    expect(recipesRepo.createOnly(), isA<Future<Response>>());
    expect(recipesRepo.getId(id: '1'), isA<Future<Response>>());
    expect(recipesRepo.updateOnly(id: '1'), isA<Future<Response>>());
    expect(recipesRepo.deleteOnly(id: '1'), isA<Future<Response>>());
  });
}
