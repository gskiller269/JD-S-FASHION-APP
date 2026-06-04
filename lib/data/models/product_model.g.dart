// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductModel _$ProductModelFromJson(Map<String, dynamic> json) =>
    _ProductModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String?,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$ProductModelToJson(_ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendor_id': instance.vendorId,
      'category_id': instance.categoryId,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'base_price': instance.basePrice,
      'discount_price': instance.discountPrice,
      'is_active': instance.isActive,
    };
