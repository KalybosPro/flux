// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:json_annotation/json_annotation.dart';

part 'partner.g.dart';

@JsonSerializable()
class Partner {
  @JsonKey(includeIfNull: false)
  final String? id;

  @JsonKey(includeIfNull: false)
  final String? name;

  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? location;

  @JsonKey(includeIfNull: false)
  final String? address;

  @JsonKey(includeIfNull: false)
  final String? phone;

  @JsonKey(includeIfNull: false)
  final String? email;

  const Partner({
    this.id,
    this.name,
    this.location,
    this.address,
    this.phone,
    this.email,
  });

  factory Partner.fromJson(Map<String, dynamic> json) =>
      _$PartnerFromJson(json);

  Map<String, dynamic> toJson() => _$PartnerToJson(this);
}
