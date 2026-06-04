import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
abstract class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    @JsonKey(name: 'vendor_id') String? vendorId,
    @JsonKey(name: 'category_id') String? categoryId,
    required String name,
    required String slug,
    required String description,
    @JsonKey(name: 'base_price') required double basePrice,
    @JsonKey(name: 'discount_price') double? discountPrice,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);
}
