// **************************************************************************
// Flux chopper Generator
// **************************************************************************

import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  @JsonKey(includeIfNull: false)
  final String? id;

  @JsonKey(includeIfNull: false)
  final String? user;

  @JsonKey(includeIfNull: false)
  final String? partner;

  @JsonKey(includeIfNull: false)
  final List<Map<String, dynamic>>? ingredients;

  @JsonKey(includeIfNull: false)
  final double? totalPrice;

  @JsonKey(includeIfNull: false)
  final String? paymentStatus;

  @JsonKey(includeIfNull: false)
  final String? orderStatus;

  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? trackingInfo;

  const Order({
    this.id,
    this.user,
    this.partner,
    this.ingredients,
    this.totalPrice,
    this.paymentStatus,
    this.orderStatus,
    this.trackingInfo,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
