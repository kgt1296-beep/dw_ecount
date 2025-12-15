import '../models/category_rule.dart';

/// =======================================================
/// CategoryAutoClassifier
///
/// 자동 분류 핵심 엔진
/// - 제품명 / 규격 / 비고 문자열을 기준으로
/// - 관리자 설정(category_rules)을 이용해
/// - 단일 분류(category_name)를 결정
///
/// 사용 위치:
/// - 엑셀 IMPORT
/// - 수기 입력 저장
/// - 데이터 수정 저장
/// - 관리자 전체 재분류
/// =======================================================
class CategoryAutoClassifier {
  /// -------------------------------------------------------
  /// 자동 분류 실행
  ///
  /// [sourceText]
  ///   - 제품명 + 규격 + 비고 등을 합친 문자열
  ///
  /// [rules]
  ///   - DB에서 불러온 CategoryRule 리스트
  ///   - 반드시 priority ASC 정렬 상태 권장
  ///
  /// 반환값:
  ///   - 매칭된 categoryName
  ///   - 아무것도 없으면 '기타'
  /// -------------------------------------------------------
  static String classify({
    required String sourceText,
    required List<CategoryRule> rules,
    String defaultCategory = '기타',
  }) {
    if (sourceText.trim().isEmpty) {
      return defaultCategory;
    }

    // 🔹 비교를 위해 대문자로 통일
    final target = sourceText.toUpperCase();

    // 🔹 우선순위 정렬 (안 되어 있어도 안전하게)
    final sortedRules = [...rules]
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final rule in sortedRules) {
      // 비활성 규칙 스킵 (이중 안전)
      if (!rule.isActive) continue;

      for (final keyword in rule.keywords) {
        final k = keyword.trim().toUpperCase();

        if (k.isEmpty) continue;

        // 🔥 핵심 매칭 로직
        if (target.contains(k)) {
          return rule.categoryName;
        }
      }
    }

    // 아무 규칙도 안 걸리면 기본값
    return defaultCategory;
  }

  /// -------------------------------------------------------
  /// 디버깅 / 관리자 미리보기용
  /// - 어떤 키워드가 매칭됐는지 같이 반환
  /// -------------------------------------------------------
  static ClassificationResult classifyWithDetail({
    required String sourceText,
    required List<CategoryRule> rules,
    String defaultCategory = '기타',
  }) {
    if (sourceText.trim().isEmpty) {
      return ClassificationResult(
        category: defaultCategory,
      );
    }

    final target = sourceText.toUpperCase();
    final sortedRules = [...rules]
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final rule in sortedRules) {
      if (!rule.isActive) continue;

      for (final keyword in rule.keywords) {
        final k = keyword.trim().toUpperCase();

        if (k.isEmpty) continue;

        if (target.contains(k)) {
          return ClassificationResult(
            category: rule.categoryName,
            matchedKeyword: keyword,
            rulePriority: rule.priority,
          );
        }
      }
    }

    return ClassificationResult(category: defaultCategory);
  }
}

/// =======================================================
/// 관리자 미리보기 / 테스트용 결과 객체
/// =======================================================
class ClassificationResult {
  final String category;
  final String? matchedKeyword;
  final int? rulePriority;

  ClassificationResult({
    required this.category,
    this.matchedKeyword,
    this.rulePriority,
  });
}
