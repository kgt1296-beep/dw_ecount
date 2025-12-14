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
      return '분류';
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
  final Color _headerColor = const Color(0xFFF5F7FA); // 테이블 헤더 배경색
  final Color _primaryColor = const Color(0xFF3F51B5); // 주요 포인트 컬러

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

      // 2. 연도 필터 적용 (선택된 연도보다 이전 자료 무시)
      if (_minYear != null) {
        result = result.where((p) {
          // dealDate가 'YYYY-MM-DD' 형식의 String이라고 가정
          // 안전하게 앞 4자리를 잘라서 연도 비교
          try {
            // dealDate가 String인지 DateTime인지 확실치 않을 때를 대비해 toString() 사용
            final yearStr = p.dealDate.toString().substring(0, 4);
            final pYear = int.tryParse(yearStr) ?? 0;
            return pYear >= _minYear!;
          } catch (e) {
            // 날짜 형식이 올바르지 않으면 검색 결과에 포함시키지 않음(혹은 포함시킴)
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

  // 엑셀 가져오기 로직 분리
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

    // 🔄 진행률 다이얼로그
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
      backgroundColor: const Color(0xFFF0F2F5), // 전체 배경색 (연한 회색)
      appBar: AppBar(
        title: const Text(
          '단가 관리',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: false,
        actions: [
          // ===============================
          // 🔥 발주서 버튼 (신규)
          // ===============================
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PurchaseRequestScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.assignment_outlined,
              size: 20,
            ),
            label: const Text(
              '발주서',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
          ),

          const SizedBox(width: 8),

          // ===============================
          // 관리자 전용 액션들
          // ===============================
          if (isAdmin) _buildAdminActions(context),

          const SizedBox(width: 8),

          // 관리자 토글 버튼
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
              // 1. 검색 영역
              _buildSearchArea(),

              // 2. 데이터 테이블 영역
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

      // ===============================
      // 관리자만 상품 추가 가능
      // ===============================
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


  // 관리자용 앱바 액션 버튼들
  Widget _buildAdminActions(BuildContext context) {
    return Row(
      children: [
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

  // 검색 영역 위젯
  Widget _buildSearchArea() {
    // 연도 리스트 생성 (2020년 ~ 현재 연도)
    final int currentYear = DateTime.now().year;
    final List<int> yearList = List.generate(
        currentYear - 2020 + 1,
            (index) => 2020 + index
    ).reversed.toList(); // 최신 연도가 위로 오게

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // [추가] 연도 필터 드롭다운
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _minYear,
                    hint: const Text('기간'),
                    icon: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    onChanged: (v) {
                      setState(() {
                        _minYear = v;
                        // 필요 시 여기서 바로 검색 실행: _doSearch();
                      });
                    },
                    items: [
                      // 전체 기간 옵션
                      const DropdownMenuItem(
                        value: null,
                        child: Text('전체 기간', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      // 연도별 옵션
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

              // 기존 검색 조건 드롭다운
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
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

              // 검색어 입력 필드
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '${searchFieldLabel(_searchField)}을(를) 입력하세요',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  ),
                  onChanged: (v) {
                    _inputKeyword = v.trim().toLowerCase();
                  },
                  onSubmitted: (_) => _doSearch(),
                ),
              ),
              const SizedBox(width: 12),

              // 검색 버튼
              ElevatedButton(
                onPressed: _doSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('조회',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 결과 테이블 영역
  Widget _buildResultArea(bool isAdmin) {
    if (!_searched) {
      return _buildEmptyState(
          Icons.search_rounded, '검색 조건을 입력하고 조회 버튼을 눌러주세요.');
    }

    if (_filtered.isEmpty) {
      return _buildEmptyState(Icons.info_outline_rounded, '검색 결과가 없습니다.');
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.grey[200],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                    MaterialStateProperty.all(_headerColor),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columnSpacing: 28,
                    horizontalMargin: 24,

                    // ===============================
                    // 🔥 컬럼 정의 (엑셀 구조 기준)
                    // ===============================
                    columns: [
                      _col('거래일자', 110),
                      _col('거래처', 140),
                      _col('구분', 80),
                      _col('제품명', 260),
                      _col('제조사', 160),
                      _col('수량', 70, numeric: true),
                      _col('단위', 80),
                      _col('총금액', 120, numeric: true),
                      _col('개당단가', 120, numeric: true),
                      _col('비고', 180),
                      if (isAdmin) _col('관리', 100, center: true),
                    ],

                    // ===============================
                    // 🔥 데이터 행
                    // ===============================
                    rows: _filtered.map((p) {
                      return DataRow(
                        cells: [
                          _cell(formatDealDate(p.dealDate)),
                          _cell(p.client ?? '', color: Colors.grey[700]),
                          _cell(p.category ?? '', isTag: true),

                          // 🔥 제품명 (괄호 제거)
                          _cell(
                            p.name,
                            bold: true,
                            size: 15,
                          ),

                          // 🔥 제조사
                          _cell(p.manufacturer ?? ''),

                          // 🔥 수량
                          _cell(p.quantity.toString(), alignRight: true),

                          // 🔥 단위
                          _cell(p.unit ?? ''),

                          // 🔥 총금액
                          _cell(
                            _fmt(p.totalPrice),
                            alignRight: true,
                            color: _primaryColor,
                            bold: true,
                          ),

                          // 🔥 개당단가
                          _cell(_fmt(p.unitPrice), alignRight: true),

                          // 🔥 비고
                          _cell(p.note ?? '', color: Colors.grey),

                          if (isAdmin)
                            DataCell(
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _actionIcon(
                                      Icons.edit_outlined,
                                      Colors.blue,
                                          () async {
                                        final changed =
                                        await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductEditScreen(product: p),
                                          ),
                                        );
                                        if (changed == true) _reload();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _actionIcon(
                                      Icons.delete_outline,
                                      Colors.red,
                                          () async {
                                        final ok =
                                        await _confirmDelete(context);
                                        if (ok) {
                                          await DB.deleteProduct(p.id);
                                          _reload();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 빈 화면 위젯
  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 관리 아이콘 버튼 스타일링
  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  DataColumn _col(String label, double width,
      {bool numeric = false, bool center = false}) {
    return DataColumn(
      numeric: numeric,
      label: Container(
        width: width,
        alignment: center
            ? Alignment.center
            : (numeric ? Alignment.centerRight : Alignment.centerLeft),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  DataCell _cell(
      String text, {
        bool bold = false,
        bool alignRight = false,
        Color? color,
        double size = 14,
        bool isTag = false,
      }) {
    if (isTag) {
      return DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return DataCell(
      Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w600 : null,
            color: color ?? Colors.black87,
            fontSize: size,
          ),
        ),
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
            child:
            const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    )) ??
        false;
  }
}