import 'package:flutter/material.dart';

import '../../models/purchase_request_item.dart';
import '../../utils/purchase_no_generator.dart';
import '../../data/purchase_request_draft_storage.dart';
import '../../data/purchase_request_excel_export.dart';

import 'product_select_dialog.dart';
import 'purchase_request_form.dart';
import 'purchase_request_items.dart';

class PurchaseRequestScreen extends StatefulWidget {
  const PurchaseRequestScreen({super.key});

  @override
  State<PurchaseRequestScreen> createState() =>
      _PurchaseRequestScreenState();
}

class _PurchaseRequestScreenState
    extends State<PurchaseRequestScreen> {
  // ===============================
  // 상태
  // ===============================
  final List<PurchaseRequestItem> _items = [];

  final _vendorCtrl = TextEditingController();
  final _managerCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  String _purchaseNo = '';

  @override
  void initState() {
    super.initState();
    _initPurchaseNo();
    _loadDraft();
  }

  Future<void> _initPurchaseNo() async {
    final no = await PurchaseNoGenerator.next();
    setState(() {
      _purchaseNo = no;
    });
  }
  @override
  void dispose() {
    _vendorCtrl.dispose();
    _managerCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  // ===============================
  // 임시저장 / 복구
  // ===============================
  Future<void> _loadDraft() async {
    final data = await PurchaseRequestDraftStorage.load();
    if (data == null) return;

    setState(() {
      _purchaseNo =
          (data['purchaseNo'] as String?) ??
              _purchaseNo;

      _vendorCtrl.text = data['vendor'] ?? '';
      _managerCtrl.text = data['manager'] ?? '';
      _memoCtrl.text = data['memo'] ?? '';

      _items
        ..clear()
        ..addAll(
          (data['items'] as List)
              .map(
                (e) =>
                PurchaseRequestItem.fromJson(e),
          ),
        );
    });
  }

  Future<void> _saveDraft() async {
    await PurchaseRequestDraftStorage.save(
      purchaseNo: _purchaseNo,
      vendor: _vendorCtrl.text,
      manager: _managerCtrl.text,
      memo: _memoCtrl.text,
      items: _items,
    );
  }

  // ===============================
  // 품목 처리
  // ===============================
  Future<void> _addItem() async {
    final item =
    await showDialog<PurchaseRequestItem>(
      context: context,
      builder: (_) => const ProductSelectDialog(),
    );

    if (item == null) return;

    setState(() {
      _items.add(item);
    });
    _saveDraft();
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _saveDraft();
  }

  void _updateQty(int index, double qty) {
    setState(() => _items[index].quantity = qty);
    _saveDraft();
  }

  void _updateUnit(int index, String unit) {
    setState(() => _items[index].unit = unit);
    _saveDraft();
  }

  void _updateNote(int index, String note) {
    setState(() => _items[index].note = note);
    _saveDraft();
  }

  // ===============================
  // 엑셀 저장
  // ===============================
  Future<void> _exportExcel() async {
    await PurchaseRequestExcelExport.export(
      purchaseNo: _purchaseNo,
      vendor: _vendorCtrl.text,
      manager: _managerCtrl.text,
      memo: _memoCtrl.text,
      items: _items,
    );

    await PurchaseRequestDraftStorage.clear();

    // ✅ 새 발주 시작
    final nextNo = await PurchaseNoGenerator.next();
    setState(() {
      _purchaseNo = nextNo;
      _items.clear();
      _vendorCtrl.clear();
      _managerCtrl.clear();
      _memoCtrl.clear();
    });
  }


  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('발주서 (견적요청)  $_purchaseNo'),
        actions: [
          IconButton(
            tooltip: '엑셀 저장',
            icon: const Icon(Icons.save_alt),
            onPressed: _exportExcel,
          ),
          IconButton(
            tooltip: '품목 추가',
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 헤더
          PurchaseRequestForm(
            vendorCtrl: _vendorCtrl,
            managerCtrl: _managerCtrl,
            memoCtrl: _memoCtrl,
          ),

          const Divider(height: 1),

          // 품목 리스트
          Expanded(
            child: PurchaseRequestItems(
              items: _items,
              onRemove: _removeItem,
              onQtyChanged: _updateQty,
              onUnitChanged: _updateUnit,
              onNoteChanged: _updateNote,
            ),
          ),
        ],
      ),
    );
  }
}
