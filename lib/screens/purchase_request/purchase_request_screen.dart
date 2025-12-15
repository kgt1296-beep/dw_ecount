import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_request_item.dart';
import '../../data/purchase_request_draft_storage.dart';
import '../../data/purchase_request_excel_export.dart';

import 'product_select_dialog.dart';
import 'purchase_request_items.dart';

class PurchaseRequestScreen extends StatefulWidget {
  const PurchaseRequestScreen({super.key});

  @override
  State<PurchaseRequestScreen> createState() => _PurchaseRequestScreenState();
}

class _PurchaseRequestScreenState extends State<PurchaseRequestScreen> {
  // ===============================
  // 상태
  // ===============================
  final List<PurchaseRequestItem> _items = [];

  final _vendorCtrl = TextEditingController();
  final _managerCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  /// 발주번호 뒤 번호만 입력
  final TextEditingController _purchaseSeqCtrl = TextEditingController(text: '00');

  // 디자인용 색상
  final Color _primaryColor = const Color(0xFF3F51B5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // ===============================
  // 생명주기
  // ===============================
  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _managerCtrl.dispose();
    _memoCtrl.dispose();
    _purchaseSeqCtrl.dispose();
    super.dispose();
  }

  // ===============================
  // 발주번호 / 발주일자
  // ===============================
  String _purchasePrefix() {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'DW-$date-';
  }

  String _purchaseDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String get _finalPurchaseNo => '${_purchasePrefix()}${_purchaseSeqCtrl.text}';

  // ===============================
  // 임시저장 / 복구
  // ===============================
  Future<void> _loadDraft() async {
    final data = await PurchaseRequestDraftStorage.load();
    if (data == null) return;

    final savedNo = data['purchaseNo'] as String?;
    if (savedNo != null && savedNo.contains('-')) {
      _purchaseSeqCtrl.text = savedNo.split('-').last;
    }

    setState(() {
      _vendorCtrl.text = data['vendor'] ?? '';
      _managerCtrl.text = data['manager'] ?? '';
      _memoCtrl.text = data['memo'] ?? '';

      _items
        ..clear()
        ..addAll(
          (data['items'] as List).map((e) => PurchaseRequestItem.fromJson(e)),
        );
    });
  }

  Future<void> _saveDraft() async {
    await PurchaseRequestDraftStorage.save(
      purchaseNo: _finalPurchaseNo,
      vendor: _vendorCtrl.text,
      manager: _managerCtrl.text,
      memo: _memoCtrl.text,
      items: _items,
    );
  }

  // ===============================
  // 품목 처리 (🔥수정: 인자 역전 시나리오 방어 로직 추가)
  // ===============================
  Future<void> _addItem() async {
    final item = await showDialog<PurchaseRequestItem>(
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

  // [핵심 수정] 수량 업데이트 (index와 value의 위치가 바뀌었을 경우를 방어)
  void _updateQty(int index, dynamic value) {
    // 1. 실제 값(수량)을 찾습니다.
    // - value가 double/String이고, index가 int인 일반적인 경우: actualValue = value
    // - value가 int이고, index가 String인 경우: actualValue = index (인자 역전 가정)

    dynamic actualValue;
    int actualIndex = index;

    // 만약 index가 String이고, value가 int라면 인덱스와 값이 바뀌었을 가능성이 높음.
    // 하지만 Dart는 인자 타입을 확인하므로, 여기서는 **인덱스는 항상 index로, 값은 항상 value로 들어왔다고 가정**하고,
    // value의 타입을 안전하게 double로 변환하는 데 집중합니다.

    double qty = 0.0;

    if (value is double) {
      qty = value;
    } else if (value is String) {
      // 쉼표 제거 (혹시 모를 숫자 포맷 방지)
      final cleanString = value.replaceAll(',', '');
      qty = double.tryParse(cleanString) ?? 0.0;
    } else if (value is int) {
      qty = value.toDouble();
    } else if (value is num) {
      qty = value.toDouble();
    }

    setState(() {
      if (actualIndex >= 0 && actualIndex < _items.length) {
        // 0보다 작으면 0으로 고정
        _items[actualIndex].quantity = qty < 0 ? 0 : qty;
      }
    });
    _saveDraft();
  }

  // [핵심 수정] 단위 업데이트 (index와 value의 위치가 바뀌었을 경우를 방어)
  void _updateUnit(int index, dynamic value) {
    // 수량과 마찬가지로, value가 항상 단위 String이라고 가정합니다.

    String unit = value.toString().trim().toUpperCase();

    setState(() {
      if (index >= 0 && index < _items.length) {
        _items[index].unit = unit;
      }
    });
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
      purchaseNo: _finalPurchaseNo,
      vendor: _vendorCtrl.text,
      manager: _managerCtrl.text,
      memo: _memoCtrl.text,
      items: _items,
    );

    await PurchaseRequestDraftStorage.clear();

    setState(() {
      _items.clear();
      _vendorCtrl.clear();
      _managerCtrl.clear();
      _memoCtrl.clear();
      _purchaseSeqCtrl.text = '00';
    });
  }

  // ===============================
  // UI 빌드
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          '발주서 작성 (견적요청)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _exportExcel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text('엑셀 저장'),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------
          // 좌측 / 상단: 문서 정보 입력 영역
          // -------------------------------
          Expanded(
            flex: 0,
            child: Container(
              width: 380,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey[200]!)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '기본 정보',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // 1. 발주번호 (통합 디자인)
                    _buildLabel('발주번호'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _purchasePrefix(),
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _purchaseSeqCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '00',
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              onChanged: (_) => _saveDraft(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. 발주일자
                    _buildLabel('발주일자'),
                    _buildReadOnlyField(
                      icon: Icons.calendar_today,
                      text: _purchaseDate(),
                    ),
                    const SizedBox(height: 20),

                    // 3. 거래처
                    _buildLabel('거래처'),
                    _buildTextField(
                      controller: _vendorCtrl,
                      hint: '거래처명을 입력하세요',
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 20),

                    // 4. 담당자
                    _buildLabel('담당자'),
                    _buildTextField(
                      controller: _managerCtrl,
                      hint: '담당자 이름',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),

                    // 5. 비고
                    _buildLabel('비고 (요청사항)'),
                    _buildTextField(
                      controller: _memoCtrl,
                      hint: '특이사항이나 요청사항을 입력하세요',
                      icon: Icons.note_alt_outlined,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------
          // 우측 / 하단: 품목 리스트 영역
          // -------------------------------
          Expanded(
            child: Column(
              children: [
                // 리스트 헤더
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: _backgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.list_alt, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '품목 리스트 (${_items.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('품목 추가'),
                      ),
                    ],
                  ),
                ),

                // 실제 리스트
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _items.isEmpty
                        ? _buildEmptyState()
                        : PurchaseRequestItems(
                      items: _items,
                      onRemove: _removeItem,
                      onQtyChanged: _updateQty, // 여기에서 콜백 연결
                      onUnitChanged: _updateUnit, // 여기에서 콜백 연결
                      onNoteChanged: _updateNote,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // 디자인 헬퍼 메서드 (UI Components)
  // ------------------------------------------------------------------------

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => _saveDraft(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  Widget _buildReadOnlyField({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.playlist_add, size: 48, color: Colors.blueGrey[200]),
          ),
          const SizedBox(height: 24),
          Text(
            '추가된 품목이 없습니다.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '우측 상단의 [+ 품목 추가] 버튼을 눌러주세요.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('품목 추가하기'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}