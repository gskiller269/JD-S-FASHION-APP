import 'dart:convert';

class OrderItemModel {
  final String productId;
  final String variantId;
  final String productName;
  final int quantity;
  final double price;
  final String? size;
  final String? color;
  final String? imageUrl;

  OrderItemModel({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.size,
    this.color,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'size': size,
      'color': color,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      variantId: map['variantId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
      size: map['size'],
      color: map['color'],
      imageUrl: map['imageUrl'],
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderItemModel.fromJson(String source) => OrderItemModel.fromMap(json.decode(source));
}

class OrderModel {
  final String orderId;
  final List<OrderItemModel> items;
  final Map<String, String> deliveryAddress;
  final String paymentMethod;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double totalAmount;
  final String orderStatus;
  final DateTime createdAt;
  final DateTime estimatedDeliveryDate;
  final String deliveryPartner;

  OrderModel({
    required this.orderId,
    required this.items,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.totalAmount,
    required this.orderStatus,
    required this.createdAt,
    required this.estimatedDeliveryDate,
    required this.deliveryPartner,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'items': items.map((x) => x.toMap()).toList(),
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'orderStatus': orderStatus,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDeliveryDate': estimatedDeliveryDate.toIso8601String(),
      'deliveryPartner': deliveryPartner,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      items: List<OrderItemModel>.from(
        (map['items'] as List<dynamic>).map((x) => OrderItemModel.fromMap(x as Map<String, dynamic>)),
      ),
      deliveryAddress: Map<String, String>.from(map['deliveryAddress'] ?? {}),
      paymentMethod: map['paymentMethod'] ?? '',
      subtotal: (map['subtotal'] as num).toDouble(),
      shippingFee: (map['shippingFee'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      orderStatus: map['orderStatus'] ?? 'Placed',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      estimatedDeliveryDate: DateTime.parse(
        map['estimatedDeliveryDate'] ?? DateTime.now().add(const Duration(days: 4)).toIso8601String(),
      ),
      deliveryPartner: map['deliveryPartner'] ?? 'Delhivery',
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderModel.fromJson(String source) => OrderModel.fromMap(json.decode(source));
}
