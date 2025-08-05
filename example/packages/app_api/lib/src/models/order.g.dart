// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String?,
  user: json['user'] as String?,
  partner: json['partner'] as String?,
  ingredients: (json['ingredients'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  totalPrice: (json['totalPrice'] as num?)?.toDouble(),
  paymentStatus: json['paymentStatus'] as String?,
  orderStatus: json['orderStatus'] as String?,
  trackingInfo: json['trackingInfo'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': ?instance.id,
  'user': ?instance.user,
  'partner': ?instance.partner,
  'ingredients': ?instance.ingredients,
  'totalPrice': ?instance.totalPrice,
  'paymentStatus': ?instance.paymentStatus,
  'orderStatus': ?instance.orderStatus,
  'trackingInfo': ?instance.trackingInfo,
};
