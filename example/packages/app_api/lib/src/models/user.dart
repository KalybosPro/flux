// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @JsonKey(includeIfNull: false)
  final String? id;

  @JsonKey(includeIfNull: false)
  final String? email;

  @JsonKey(includeIfNull: false)
  final List<String>? roles;

  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? preferences;

  @JsonKey(includeIfNull: false)
  final List<String>? favorites;

  const User({
    this.id,
    this.email,
    this.roles,
    this.preferences,
    this.favorites,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
