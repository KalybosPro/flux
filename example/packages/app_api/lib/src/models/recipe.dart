// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:json_annotation/json_annotation.dart';

part 'recipe.g.dart';

@JsonSerializable()
class Recipe {
  @JsonKey(includeIfNull: false)
  final String? id;

  @JsonKey(includeIfNull: false)
  final String? title;

  @JsonKey(includeIfNull: false)
  final String? description;

  @JsonKey(includeIfNull: false)
  final String? category;

  @JsonKey(includeIfNull: false)
  final List<Map<String, dynamic>>? ingredients;

  const Recipe({
    this.id,
    this.title,
    this.description,
    this.category,
    this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeToJson(this);
}
