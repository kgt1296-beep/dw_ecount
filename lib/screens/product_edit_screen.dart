import 'package:flutter/material.dart';

import '../data/db.dart';
import '../models/product.dart';

class ProductEditScreen extends StatefulWidget {
  final Product? product;

  const ProductEditScreen({super.key, this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController dealDateCtrl;
  late TextEditingController clientCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController manufacturerCtrl;
  late TextEditingController nameCtrl;
  late TextEditingController specCtrl;
  late TextEditingController unitCtrl;
  late TextEditingController quantityCtrl;
  late TextEditingController totalPriceCtrl;
  late TextEditingController noteCtrl;

  int _unitPrice = 0;

  // 디자인용 색상
  final Color _primaryColor = const Color(0xFF3F51B5);
  final Color _backgroundColor = const Color(0xFFF0F2F5);

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    dealDateCtrl = TextEditingController(text: p?.dealDate ?? '');
    clientCtrl = TextEditingController(text: p?.client ?? '');
    categoryCtrl = TextEditingController(text: p?.category ?? '');
    manufacturerCtrl = TextEditingController(text: p?.manufacturer ?? '');
    nameCtrl = TextEditingController(text: p?.name ?? '');
    specCtrl = TextEditingController(text: p?.spec ?? '');
    unitCtrl = TextEditingController(text: p?.unit ?? '');
    quantityCtrl =
        TextEditingController(text: p != null ? p.quantity.toString() : '1');
    totalPriceCtrl =
        TextEditingController(text: p != null ? p.totalPrice.toString() : '');
    noteCtrl = TextEditingController(text: p?.note ?? '');

    _recalcUnitPrice();
    quantityCtrl.addListener(_recalcUnitPrice);
    totalPriceCtrl.addListener(_recalcUnitPrice);
  }

  void _recalcUnitPrice() {
    final q = int.tryParse(quantityCtrl.text) ?? 0;
    final t = int.tryParse(totalPriceCtrl.text) ?? 0;

    setState(() {
      _unitPrice = q > 0 ? (t ~/ q) : 0;
    });
  }

  @override
  void dispose() {
    dealDateCtrl.dispose();
    clientCtrl.dispose();
    categoryCtrl.dispose();
    manufacturerCtrl.dispose();
    nameCtrl.dispose();
    specCtrl.dispose();
    unitCtrl.dispose();
    quantityCtrl.dispose();
    totalPriceCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          isEdit ? '제품 정보 수정' : '새 제품 등록',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700), // 너무 넓어지지 않게 제한
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildBasicInfoCard(),
                  const SizedBox(height: 24),
                  _buildPriceInfoCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 기본 정보 카드 (제품명, 분류 등)
  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _field(dealDateCtrl, '거래일자', icon: Icons.calendar_today),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child:
                  _field(clientCtrl, '거래처', required: true, icon: Icons.business),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _field(categoryCtrl, '분류', icon: Icons.category_outlined),
                ),
                const SizedBox(width: 32),
              ],
            ),
            const SizedBox(height: 16),
            _field(nameCtrl, '제품명', required: true, icon: Icons.inventory_2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _field(unitCtrl, '단위', icon: Icons.pie_chart_outline),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _field(noteCtrl, '비고', maxLines: 3, icon: Icons.note_alt_outlined),
          ],
        ),
      ),
    );
  }

  // 가격 정보 카드 (계산 로직 포함)
  Widget _buildPriceInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '가격 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    quantityCtrl,
                    '수량',
                    required: true,
                    keyboard: TextInputType.number,
                    icon: Icons.numbers,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _field(
                    totalPriceCtrl,
                    '총금액',
                    required: true,
                    keyboard: TextInputType.number,
                    icon: Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 자동 계산된 단가 표시 영역
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '개당 단가 (자동계산)',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_fmt(_unitPrice)} 원',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 하단 버튼 영역
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('취소', style: TextStyle(color: Colors.black54)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
              child: const Text(
                '저장하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
      TextEditingController ctrl,
      String label, {
        bool required = false,
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
        IconData? icon,
      }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintText: '$label 입력',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.grey[50], // 연한 회색 배경
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none, // 기본 테두리 없음
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label을(를) 입력해주세요' : null
          : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'deal_date': dealDateCtrl.text.trim(),
      'client': clientCtrl.text.trim(),
      'category': categoryCtrl.text.trim(),
      'manufacturer': manufacturerCtrl.text.trim(),
      'name': nameCtrl.text.trim(),
      'spec': specCtrl.text.trim(),
      'unit': unitCtrl.text.trim(),
      'quantity': int.parse(quantityCtrl.text),
      'total_price': int.parse(totalPriceCtrl.text),
      'note': noteCtrl.text.trim(),
    };

    if (widget.product == null) {
      await DB.insertProduct(data);
    } else {
      await DB.updateProduct(widget.product!.id, data);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _fmt(num v) {
    return v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
    );
  }
}