import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../data/db.dart';
import '../data/db_export.dart';
import '../data/db_replace.dart';
import '../data/excel_export.dart';
import '../data/excel_import.dart';
import '../data/excel_import_template.dart';
import '../models/product.dart';
import '../widgets/admin_toggle_button.dart';
import 'product_edit_screen.dart';
import '../utils/date_utils.dart';
import 'purchase_request/purchase_request_screen.dart';
import 'admin/category_rule_manage_screen.dart';

/// ===============================
/// 검색 필드 enum
/// ===============================
enum PriceSearchField {
  category,
  productName,
}

String searchFieldLabel(PriceSearchField field) {
  switch (field) {
    case PriceSearchField.category:
      return '구분';
    case PriceSearchField.productName:
      return '제품명';
  }
}

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  late Future<void> _future;

  // 🔍 검색 상태
  int? _minYear; // null이면 연도 필터 미적용 (전체)
  PriceSearchField _searchField = PriceSearchField.productName;
  String _inputKeyword = '';
  String _appliedKeyword = '';
  bool _searched = false;

  // 전체 데이터
  List<Product> _allItems = [];
  // 필터링된 데이터
  List<Product> _filtered = [];

  // 디자인용 색상 팔레트
  final Color _primaryColor = const Color(0xFF3F51B5); // 주요 포인트 컬러
  final Color _backgroundColor = const Color(0xFFF5F7FA); // 배경색

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = DB.getProducts().then((rows) {
      _allItems = rows.map((e) => Product.fromMap(e)).toList();
    });
  }

  void _reload() {
    setState(() {
      _searched = false;
      _filtered.clear();
      _load();
    });
  }

  void _doSearch() {
    setState(() {
      _appliedKeyword = _inputKeyword;
      _searched = true;

      // 1. 전체 리스트에서 시작
      Iterable<Product> result = _allItems;

      // 2. 연도 필터 적용
      if (_minYear != null) {
        result = result.where((p) {
          try {
            final yearStr = p.dealDate.toString().substring(0, 4);
            final pYear = int.tryParse(yearStr) ?? 0;
            return pYear >= _minYear!;
          } catch (e) {
            return false;
          }
        });
      }

      // 3. 키워드 검색 필터 적용
      if (_appliedKeyword.isNotEmpty) {
        result = result.where((p) {
          switch (_searchField) {
            case PriceSearchField.category:
              return (p.category ?? '').toLowerCase().contains(_appliedKeyword);
            case PriceSearchField.productName:
              return p.name.toLowerCase().contains(_appliedKeyword);
          }
        });
      }

      _filtered = result.toList();
    });
  }

  String _fmt(num v) {
    return v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
    );
  }

  // ===============================
  // DB 교체 예약
  // ===============================
  Future<void> _requestDbReplace() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('DB 교체'),
        content: const Text(
          '외부 DB 파일로 교체합니다.\n'
              '프로그램 종료 후 적용됩니다.\n\n'
              '계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('교체'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await DBReplaceService.requestReplace();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('교체 예약 완료'),
        content: const Text(
          'DB 교체가 예약되었습니다.\n'
              '프로그램을 종료 후 다시 실행해주세요.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => exit(0),
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  // 엑셀 가져오기 로직
  Future<void> _handleExcelImport() async {
    final mode = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('엑셀 가져오기'),
        content: const Text('기존 데이터를 어떻게 처리할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('추가'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('덮어쓰기'),
          ),
        ],
      ),
    );

    if (mode == null) return;

    int current = 0;
    int total = 0;
    late void Function(void Function()) dialogSetState;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('엑셀 가져오는 중'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: total == 0 ? null : current / total,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$current / $total',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      await ExcelImport.importFromTemplate(
        clearBeforeInsert: mode,
        onProgress: (c, t) {
          current = c;
          total = t;
          dialogSetState(() {});
        },
      );
    } finally {
      if (context.mounted) {
        Navigator.pop(context); // 다이얼로그 닫기
      }
    }

    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppState>().isAdmin;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          '단가 관리',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PurchaseRequestScreen(),
                ),
              );
            },
            icon: const Icon(Icons.assignment_outlined, size: 20),
            label: const Text(
              '발주서',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          if (isAdmin) _buildAdminActions(context),
          const SizedBox(width: 8),
          const AdminToggleButton(),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildSearchArea(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildResultArea(isAdmin),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductEditScreen(),
            ),
          );
          if (changed == true) _reload();
        },
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: '자동 분류 규칙 관리',
          icon: const Icon(Icons.rule_folder_outlined),
          onPressed: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoryRuleManageScreen(),
              ),
            );
            if (changed == true) _reload();
          },
        ),
        PopupMenuButton<String>(
          tooltip: 'DB 관리',
          icon: const Icon(Icons.storage_outlined),
          onSelected: (value) async {
            if (value == 'export') {
              await DBExportService.exportDatabase();
            } else if (value == 'replace') {
              await _requestDbReplace();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_rounded, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('DB 내보내기 (백업)'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'replace',
              child: Row(
                children: [
                  Icon(Icons.restore_page_outlined, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('DB 교체 (복구)'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Import 템플릿 다운로드',
          icon: const Icon(Icons.description_outlined),
          onPressed: ExcelImportTemplate.downloadTemplate,
        ),
        IconButton(
          tooltip: '엑셀 가져오기',
          icon: const Icon(Icons.upload_file_outlined),
          onPressed: _handleExcelImport,
        ),
        IconButton(
          tooltip: '엑셀 내보내기',
          icon: const Icon(Icons.download_rounded),
          onPressed: () async {
            await ExcelExport.exportProducts(_filtered);
          },
        ),
      ],
    );
  }

  Widget _buildSearchArea() {
    final int currentYear = DateTime.now().year;
    final List<int> yearList = List.generate(
        currentYear - 2020 + 1, (index) => 2020 + index).reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _minYear,
                    hint: const Text('기간', style: TextStyle(fontSize: 14)),
                    icon: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    onChanged: (v) {
                      setState(() {
                        _minYear = v;
                      });
                    },
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('전체 기간', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      ...yearList.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year년 이후', style: const TextStyle(fontWeight: FontWeight.w500)),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PriceSearchField>(
                    value: _searchField,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _searchField = v);
                    },
                    items: PriceSearchField.values.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(
                          searchFieldLabel(f),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '${searchFieldLabel(_searchField)}을(를) 입력하세요',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  onChanged: (v) => _inputKeyword = v.trim().toLowerCase(),
                  onSubmitted: (_) => _doSearch(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _doSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('조회', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 [개선된 UI] 반응형 리스트 (오른쪽 여백 제거 및 디자인 개선)
  // ============================================================

  // 컬럼별 화면 비율 설정 (Flex)
  final Map<String, int> _colFlex = {
    'date': 2,
    'client': 3,
    'category': 2,
    'name': 6, // 이름이 가장 긺
    'maker': 3,
    'qty': 1,
    'unit': 1,
    'total': 2,
    'price': 2,
    'note': 3,
    'action': 2,
  };

  Widget _buildResultArea(bool isAdmin) {
    if (!_searched) {
      return _buildEmptyState(Icons.search_rounded, '검색 조건을 입력하고 조회 버튼을 눌러주세요.');
    }

    if (_filtered.isEmpty) {
      return _buildEmptyState(Icons.info_outline_rounded, '검색 결과가 없습니다.');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. 헤더 영역
          _buildTableHeader(isAdmin),

          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // 2. 리스트 영역 (Expanded로 채움)
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFF5F5F5)),
                itemBuilder: (context, index) {
                  return _buildTableRow(_filtered[index], isAdmin);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 테이블 헤더
  Widget _buildTableHeader(bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _headerText('거래일자', flex: _colFlex['date']!),
          _headerText('거래처', flex: _colFlex['client']!),
          _headerText('구분', flex: _colFlex['category']!, center: true),
          _headerText('제품명', flex: _colFlex['name']!),
          _headerText('', flex: _colFlex['maker']!),
          _headerText('수량', flex: _colFlex['qty']!, alignRight: true),
          _headerText('단위', flex: _colFlex['unit']!, center: true),
          _headerText('총금액', flex: _colFlex['total']!, alignRight: true),
          _headerText('개당단가', flex: _colFlex['price']!, alignRight: true),
          _headerText('비고', flex: _colFlex['note']!),
          if (isAdmin) _headerText('관리', flex: _colFlex['action']!, center: true),
        ],
      ),
    );
  }

  // 데이터 행
  Widget _buildTableRow(Product p, bool isAdmin) {
    return Material(
      color: Colors.white,
      child: InkWell(
        hoverColor: _primaryColor.withOpacity(0.04),
        onTap: () {
          // 필요시 상세 보기 기능 추가
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 날짜
              _rowText(formatDealDate(p.dealDate), flex: _colFlex['date']!, color: Colors.grey[600]),

              // 거래처
              _rowText(p.client ?? '-', flex: _colFlex['client']!, color: Colors.grey[800]),

              // 구분 (뱃지 스타일)
              Expanded(
                flex: _colFlex['category']!,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      p.category ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // 제품명 (강조)
              _rowText(p.name, flex: _colFlex['name']!, bold: true, size: 14),

              // 제조사
              _rowText(p.manufacturer ?? '', flex: _colFlex['maker']!, color: Colors.grey[600]),

              // 수량
              _rowText(p.quantity.toString(), flex: _colFlex['qty']!, alignRight: true),

              // 단위
              _rowText(p.unit ?? '', flex: _colFlex['unit']!, center: true, color: Colors.grey[600]),

              // 총금액 (색상 강조)
              _rowText(_fmt(p.totalPrice), flex: _colFlex['total']!, alignRight: true, color: _primaryColor, bold: true),

              // 단가
              _rowText(_fmt(p.unitPrice), flex: _colFlex['price']!, alignRight: true),

              // 비고
              _rowText(p.note ?? '', flex: _colFlex['note']!, color: Colors.grey[500], size: 13),

              // 관리 버튼 (Admin)
              if (isAdmin)
                Expanded(
                  flex: _colFlex['action']!,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionIcon(Icons.edit_outlined, Colors.blue, () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => ProductEditScreen(product: p)),
                        );
                        if (changed == true) _reload();
                      }),
                      const SizedBox(width: 8),
                      _actionIcon(Icons.delete_outline, Colors.red, () async {
                        final ok = await _confirmDelete(context);
                        if (ok) {
                          await DB.deleteProduct(p.id);
                          _reload();
                        }
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------
  // UI 헬퍼 메서드들
  // -------------------------

  Widget _headerText(String text, {required int flex, bool alignRight = false, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : (alignRight ? TextAlign.right : TextAlign.left),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _rowText(String text, {
    required int flex,
    bool alignRight = false,
    bool center = false,
    bool bold = false,
    Color? color,
    double size = 14,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4), // 간격 확보
        child: Text(
          text,
          textAlign: center ? TextAlign.center : (alignRight ? TextAlign.right : TextAlign.left),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: color ?? Colors.black87,
            fontSize: size,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 항목을 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    )) ?? false;
  }
}