class Product {
  final int id;

  // ===============================
  // 거래 정보
  // ===============================
  final String? dealDate;       // 거래일자 (YYYY-MM-DD)
  final String client;          // 거래처
  final String category;        // 분류
  final String? manufacturer;   // 제조사

  // ===============================
  // 제품 정보
  // ===============================
  final String name;            // 제품명
  final String? spec;           // 규격
  final String? unit;           // 단위

  // ===============================
  // 금액 정보
  // ===============================
  final int quantity;           // 수량
  final int totalPrice;         // 총금액

  final String? note;           // 비고

  Product({
    required this.id,
    this.dealDate,
    required this.client,
    required this.category,
    this.manufacturer,
    required this.name,
    this.spec,
    this.unit,
    required this.quantity,
    required this.totalPrice,
    this.note,
  });

  // =====================================
  // DB → Dart
  // =====================================
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      dealDate: map['deal_date'] as String?,
      client: map['client'] as String,
      category: map['category'] as String,
      manufacturer: map['manufacturer'] as String?,
      name: map['name'] as String,
      spec: map['spec'] as String?,
      unit: map['unit'] as String?,
      quantity: map['quantity'] as int,
      totalPrice: map['total_price'] as int,
      note: map['note'] as String?,
    );
  }

  // =====================================
  // Dart → DB
  // =====================================
  Map<String, dynamic> toMap() {
    return {
      'deal_date': dealDate,
      'client': client,
      'category': category,
      'manufacturer': manufacturer,
      'name': name,
      'spec': spec,
      'unit': unit,
      'quantity': quantity,
      'total_price': totalPrice,
      'note': note,
    };
  }

  // =====================================
  // 계산용 (DB 컬럼 아님)
  // =====================================
  int get unitPrice {
    if (quantity <= 0) return 0;
    return totalPrice ~/ quantity;
  }
}
