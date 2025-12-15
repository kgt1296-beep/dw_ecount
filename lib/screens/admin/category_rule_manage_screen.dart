import 'package:flutter/material.dart';

import '../../data/category_rule_dao.dart';
import '../../data/product_reclassifier.dart';
import '../../models/category_rule.dart';
import '../../widgets/category_rule_edit_dialog.dart';

class CategoryRuleManageScreen extends StatefulWidget {
  const CategoryRuleManageScreen({super.key});

  @override
  State<CategoryRuleManageScreen> createState() =>
      _CategoryRuleManageScreenState();
}

class _CategoryRuleManageScreenState
    extends State<CategoryRuleManageScreen> {
  final CategoryRuleDao _dao = CategoryRuleDao();

  List<CategoryRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _loading = true);
    final rules = await _dao.fetchAllRules();
    setState(() {
      _rules = rules;
      _loading = false;
    });
  }

  Future<void> _toggleActive(CategoryRule rule) async {
    if (rule.id == null) return;

    if (rule.isActive) {
      await _dao.deactivateRule(rule.id!);
    } else {
      await _dao.activateRule(rule.id!);
    }
    _loadRules();
  }

  Future<void> _movePriority(int index, int direction) async {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _rules.length) return;

    final temp = _rules[index];
    _rules[index] = _rules[newIndex];
    _rules[newIndex] = temp;

    await _dao.updatePriorities(_rules);
    _loadRules();
  }

  Future<void> _addRule() async {
    final newRule = await showDialog<CategoryRule>(
      context: context,
      builder: (_) => const CategoryRuleEditDialog(),
    );

    if (newRule == null) return;

    final maxPriority = _rules.isEmpty
        ? 0
        : _rules.map((e) => e.priority).reduce((a, b) => a > b ? a : b);

    final ruleWithPriority = CategoryRule(
      categoryName: newRule.categoryName,
      keywords: newRule.keywords,
      priority: maxPriority + 1,
      isActive: true,
    );

    await _dao.insertRule(ruleWithPriority);
    await _loadRules();
  }

  Future<void> _reclassifyAll() async {
    await ProductReclassifier.reclassifyAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 상품 분류가 갱신되었습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자동 분류 규칙 관리')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: _buildList()),
          const Divider(height: 1),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: const Row(
        children: [
          SizedBox(width: 40, child: Text('우선')),
          Expanded(flex: 2, child: Text('분류명')),
          Expanded(flex: 4, child: Text('키워드')),
          SizedBox(width: 60, child: Text('활성')),
          SizedBox(width: 80, child: Text('관리')),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_rules.isEmpty) {
      return const Center(child: Text('등록된 규칙이 없습니다.'));
    }

    return ListView.separated(
      itemCount: _rules.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final rule = _rules[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text('${rule.priority}')),
              Expanded(
                flex: 2,
                child: Text(rule.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(flex: 4, child: Text(rule.keywordLabel)),
              SizedBox(
                width: 60,
                child: Switch(
                  value: rule.isActive,
                  onChanged: (_) => _toggleActive(rule),
                ),
              ),
              SizedBox(
                width: 80,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      onPressed: () => _movePriority(index, -1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      onPressed: () => _movePriority(index, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('규칙 추가'),
            onPressed: _addRule,
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('전체 재분류'),
            onPressed: () async {
              await ProductReclassifier.reclassifyAll();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('전체 상품 분류가 갱신되었습니다')),
              );

              // 🔥 핵심: 이전 화면으로 true 반환
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}
