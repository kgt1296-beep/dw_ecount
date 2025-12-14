import 'package:flutter/material.dart';
import '../../models/purchase_request_item.dart';

/// ===============================================
///  발주서(견적요청) 품목 리스트
///  - 단가 없음
///  - 규격 제거
///  - 수량 / 단위 / 비고 수정 가능
///  - 삭제 가능
///  - 화면 가로폭 최대 사용
/// ===============================================
class PurchaseRequestItems extends StatelessWidget {
  final List<PurchaseRequestItem> items;
  final Function(int index) onRemove;
  final Function(int index, double qty) onQtyChanged;
  final Function(int index, String unit) onUnitChanged;
  final Function(int index, String note) onNoteChanged;

  const PurchaseRequestItems({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onQtyChanged,
    required this.onUnitChanged,
    required this.onNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          '추가된 품목이 없습니다.\n상단 + 버튼으로 품목을 추가하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            // 🔥 화면 전체 폭 이상 강제
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 28,
              headingRowHeight: 44,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 60,

              // ===============================
              // 컬럼 정의
              // ===============================
              columns: const [
                DataColumn(label: _Header('분류')),
                DataColumn(label: _Header('제품명')),
                DataColumn(label: _Header('수량')),
                DataColumn(label: _Header('단위')),
                DataColumn(label: _Header('비고')),
                DataColumn(label: _Header('관리')),
              ],

              // ===============================
              // rows
              // ===============================
              rows: List.generate(items.length, (index) {
                final item = items[index];

                return DataRow(
                  cells: [
                    DataCell(_CategoryCell(item.category)),
                    DataCell(_ProductNameCell(item.productName)),
                    DataCell(
                      _QtyCell(
                        initialValue: item.quantity,
                        onChanged: (v) => onQtyChanged(index, v),
                      ),
                    ),
                    DataCell(
                      _UnitInputCell(
                        initialValue: item.unit,
                        onChanged: (v) => onUnitChanged(index, v),
                      ),
                    ),
                    DataCell(
                      _NoteCell(
                        initialValue: item.note,
                        onChanged: (v) => onNoteChanged(index, v),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: '삭제',
                        onPressed: () => onRemove(index),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// ===============================================
///  공통 헤더
/// ===============================================
class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// ===============================================
///  분류 셀 (슬림)
/// ===============================================
class _CategoryCell extends StatelessWidget {
  final String text;
  const _CategoryCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// ===============================================
///  🔥 제품명 셀 (최대 폭)
/// ===============================================
class _ProductNameCell extends StatelessWidget {
  final String text;
  const _ProductNameCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460, // 🔥 좌우 여백 흡수
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// ===============================================
///  수량 입력 셀
/// ===============================================
class _QtyCell extends StatelessWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;

  const _QtyCell({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
      text: initialValue.toStringAsFixed(
        initialValue % 1 == 0 ? 0 : 2,
      ),
    );

    return SizedBox(
      width: 80,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        onChanged: (v) {
          final parsed = double.tryParse(v);
          if (parsed != null) {
            onChanged(parsed);
          }
        },
      ),
    );
  }
}

/// ===============================================
///  🔥 단위 입력 셀 (수정 가능)
/// ===============================================
class _UnitInputCell extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _UnitInputCell({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: initialValue);

    return SizedBox(
      width: 70,
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// ===============================================
///  비고 입력 셀
/// ===============================================
class _NoteCell extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _NoteCell({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_NoteCell> createState() => _NoteCellState();
}

class _NoteCellState extends State<_NoteCell> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _NoteCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부 값이 바뀌었을 때만 동기화
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _ctrl.text) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: TextField(
        controller: _ctrl,
        textDirection: TextDirection.ltr, // 🔒 보조 안전장치
        textAlign: TextAlign.left,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}


