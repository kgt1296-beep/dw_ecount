import 'package:flutter/material.dart';
import '../models/category_rule.dart';

/// =======================================================
/// 자동 분류 규칙 추가 / 수정 다이얼로그
/// =======================================================
class CategoryRuleEditDialog extends StatefulWidget {
  final CategoryRule? rule;

  const CategoryRuleEditDialog({super.key, this.rule});

  @override
  State<CategoryRuleEditDialog> createState() =>
      _CategoryRuleEditDialogState();
}

class _CategoryRuleEditDialogState extends State<CategoryRuleEditDialog> {
  late TextEditingController _categoryCtrl;
  late TextEditingController _keywordsCtrl;

  @override
  void initState() {
    super.initState();

    _categoryCtrl =
        TextEditingController(text: widget.rule?.categoryName ?? '');
    _keywordsCtrl =
        TextEditingController(text: widget.rule?.keywordLabel ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? '규칙 추가' : '규칙 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(labelText: '분류명'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keywordsCtrl,
            decoration: const InputDecoration(
              labelText: '키워드 (콤마로 구분)',
              hintText: 'PLC,QCPU,XGK',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('취소'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('저장'),
          onPressed: () {
            if (_categoryCtrl.text.trim().isEmpty) return;

            Navigator.pop(
              context,
              CategoryRule(
                id: widget.rule?.id,
                categoryName: _categoryCtrl.text.trim(),
                priority: widget.rule?.priority ?? 999,
                keywords: _keywordsCtrl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                isActive: widget.rule?.isActive ?? true,
              ),
            );
          },
        ),
      ],
    );
  }
}
