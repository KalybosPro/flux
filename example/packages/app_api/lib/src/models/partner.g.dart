// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Partner _$PartnerFromJson(Map<String, dynamic> json) => Partner(
  id: json['id'] as String?,
  name: json['name'] as String?,
  location: json['location'] as Map<String, dynamic>?,
  address: json['address'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$PartnerToJson(Partner instance) => <String, dynamic>{
  'id': ?instance.id,
  'name': ?instance.name,
  'location': ?instance.location,
  'address': ?instance.address,
  'phone': ?instance.phone,
  'email': ?instance.email,
};
