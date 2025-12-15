import 'package:flutter/material.dart';
import '../data/category_auto_classifier.dart';
import '../models/category_rule.dart';

class CategoryRulePreviewDialog extends StatefulWidget {
  final List<CategoryRule> rules;

  const CategoryRulePreviewDialog({super.key, required this.rules});

  @override
  State<CategoryRulePreviewDialog> createState() =>
      _CategoryRulePreviewDialogState();
}

class _CategoryRulePreviewDialogState
    extends State<CategoryRulePreviewDialog> {
  final TextEditingController _inputCtrl = TextEditingController();
  ClassificationResult? _result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('자동 분류 미리보기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _inputCtrl,
            decoration: const InputDecoration(
              hintText: '제품명 / 규격 입력',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            child: const Text('분류 테스트'),
            onPressed: () {
              setState(() {
                _result = CategoryAutoClassifier.classifyWithDetail(
                  sourceText: _inputCtrl.text,
                  rules: widget.rules,
                );
              });
            },
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            Text('결과 분류: ${_result!.category}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_result!.matchedKeyword != null)
              Text('매칭 키워드: ${_result!.matchedKeyword}'),
          ],
        ],
      ),
      actions: [
        TextButton(
          child: const Text('닫기'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
