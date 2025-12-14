import 'product.dart';

class PurchaseRequestItem {
  final int productId;
  final String category;
  final String productName;

  double quantity;
  String unit;
  String note;

  PurchaseRequestItem({
    required this.productId,
    required this.category,
    required this.productName,
    this.quantity = 1,
    this.unit = '',
    this.note = '',
  });

  // ===============================================
  // 🔥 Product → PurchaseRequestItem 변환
  // ===============================================
  factory PurchaseRequestItem.fromProduct(Product p) {
    return PurchaseRequestItem(
      productId: p.id,
      category: p.category ?? '',
      productName: p.name,
      quantity: 1,
      unit: p.unit ?? 'EA', // 기본 단위
      note: '',
    );
  }

  // ===============================================
  // JSON 저장용
  // ===============================================
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'category': category,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'note': note,
    };
  }

  factory PurchaseRequestItem.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestItem(
      productId: json['productId'] as int,
      category: json['category'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] ?? '',
      note: json['note'] ?? '',
    );
  }
}
