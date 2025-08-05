// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
  id: json['id'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  category: json['category'] as String?,
  ingredients: (json['ingredients'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$RecipeToJson(Recipe instance) => <String, dynamic>{
  'id': ?instance.id,
  'title': ?instance.title,
  'description': ?instance.description,
  'category': ?instance.category,
  'ingredients': ?instance.ingredients,
};
