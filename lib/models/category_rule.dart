class CategoryRule {
  final int? id;
  final String categoryName;
  final List<String> keywords;
  final int priority;
  final bool isActive;

  CategoryRule({
    this.id,
    required this.categoryName,
    required this.keywords,
    required this.priority,
    this.isActive = true,
  });

  factory CategoryRule.fromMap(Map<String, dynamic> map) {
    return CategoryRule(
      id: map['id'] as int?,
      categoryName: map['category_name'] as String,

      // 🔥 핵심 수정: TEXT → List<String>
      keywords: (map['keywords'] as String)
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList(),

      priority: map['priority'] as int,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_name': categoryName,

      // 🔥 List → TEXT
      'keywords': keywords.join(','),

      'priority': priority,
      'is_active': isActive ? 1 : 0,
    };
  }

  String get keywordLabel => keywords.join(', ');
}
