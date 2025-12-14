import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../models/product.dart';
import '../../models/purchase_request_item.dart';

/// ===============================================
///  제품 선택 다이얼로그
///  - DB 검색 + 수동 입력
///  - 반환 타입: PurchaseRequestItem (단일)
/// ===============================================
class ProductSelectDialog extends StatefulWidget {
  const ProductSelectDialog({super.key});

  @override
  State<ProductSelectDialog> createState() => _ProductSelectDialogState();
}

class _ProductSelectDialogState extends State<ProductSelectDialog> {
  List<Product> _allProducts = [];
  List<Product> _filtered = [];

  final _searchCtrl = TextEditingController();
  String _selectedCategory = '전체';

  bool _searched = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final rows = await DB.getProducts();
    setState(() {
      _allProducts = rows.map(Product.fromMap).toList();
    });
  }

  Future<void> _onSearch() async {
    setState(() {
      _searched = true;
      _loading = true;
    });

    final keyword = _searchCtrl.text.trim().toLowerCase();

    _filtered = _allProducts.where((p) {
      final matchCategory =
          _selectedCategory == '전체' || p.category == _selectedCategory;
      final matchKeyword =
          keyword.isEmpty ||
              p.name.toLowerCase().contains(keyword) ||
              (p.spec ?? '').toLowerCase().contains(keyword);
      return matchCategory && matchKeyword;
    }).toList();

    setState(() => _loading = false);
  }

  List<String> get _categories {
    final set = <String>{'전체'};
    for (final p in _allProducts) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return set.toList();
  }

  /// ✅ 수동 입력
  Future<void> _onManualAdd() async {
    final item = await showDialog<PurchaseRequestItem>(
      context: context,
      builder: (_) => const _ManualProductDialog(),
    );

    if (!mounted || item == null) return;

    // ✅ 여기서 딱 한 번만 pop
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 900,
        height: 600,
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text('제품 선택',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _onManualAdd,
                    icon: const Icon(Icons.edit),
                    label: const Text('수동 입력'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 검색
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, // 🔥 핵심
                      value: _selectedCategory,
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            overflow: TextOverflow.ellipsis, // 🔥 넘침 방지
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        _selectedCategory = v ?? '전체';
                      },
                      decoration: const InputDecoration(
                        labelText: '분류',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onSubmitted: (_) => _onSearch(),
                      decoration: const InputDecoration(
                        labelText: '제품명 / 규격 검색',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _onSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('검색'),
                  ),
                ],
              ),
            ),

            const Divider(),

            // 결과
            Expanded(
              child: !_searched
                  ? const Center(
                child: Text(
                  '검색 조건을 입력한 후\n[검색] 버튼을 눌러주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('분류')),
                    DataColumn(label: Text('제품명')),
                    DataColumn(label: Text('규격')),
                    DataColumn(label: Text('단위')),
                    DataColumn(label: Text('선택')),
                  ],
                  rows: _filtered.map((p) {
                    return DataRow(cells: [
                      DataCell(Text(p.category)),
                      DataCell(Text(p.name)),
                      DataCell(Text(p.spec ?? '')),
                      DataCell(Text(p.unit ?? '')),
                      DataCell(
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              PurchaseRequestItem.fromProduct(p),
                            );
                          },
                          child: const Text('선택'),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// ===============================================
///  수동 입력 다이얼로그
/// ===============================================
class _ManualProductDialog extends StatefulWidget {
  const _ManualProductDialog();

  @override
  State<_ManualProductDialog> createState() => _ManualProductDialogState();
}

class _ManualProductDialogState extends State<_ManualProductDialog> {
  final _categoryCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'EA');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('품목 수동 입력'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: '분류')),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '제품명')),
          TextField(controller: _unitCtrl, decoration: const InputDecoration(labelText: '단위')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) return;

            Navigator.pop(
              context,
              PurchaseRequestItem(
                productId: -1,
                category: _categoryCtrl.text.trim(),
                productName: _nameCtrl.text.trim(),
                unit: _unitCtrl.text.trim(),
                quantity: 1,
                note: '',
              ),
            );
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}

/// ===============================================
///  공통 셀
/// ===============================================
class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
