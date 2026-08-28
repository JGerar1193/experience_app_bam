import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/order.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double total;
  final String paymentMethod;
  final String? selectedCard;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.selectedCard,
    required this.createdAt,
  });

  // Convierte un Map (JSON) a OrderModel
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      items: (json['items'] as List)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      selectedCard: json['selectedCard'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Convierte un documento Firestore a OrderModel
  factory OrderModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return OrderModel(
      id: docId,
      userId: data['userId'] as String? ?? '',
      items: (data['items'] as List)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (data['total'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] as String,
      selectedCard: data['selectedCard'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convierte OrderModel a Map para Firestore (sin el id — va en el doc ID)
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'total': total,
      'paymentMethod': paymentMethod,
      'selectedCard': selectedCard,
      'createdAt': FieldValue.serverTimestamp(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  // Convierte OrderModel a Map para guardar en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'selectedCard': selectedCard,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convierte OrderModel a la entidad del dominio
  Order toEntity() {
    return Order(
      id: id,
      userId: userId,
      items: items.map((e) => e.toEntity()).toList(),
      total: total,
      paymentMethod: paymentMethod,
      selectedCard: selectedCard,
      createdAt: createdAt,
    );
  }

  // Crea un OrderModel desde la entidad del dominio
  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      userId: order.userId,
      items: order.items.map((e) => CartItemModel.fromEntity(e)).toList(),
      total: order.total,
      paymentMethod: order.paymentMethod,
      selectedCard: order.selectedCard,
      createdAt: order.createdAt,
    );
  }
}
