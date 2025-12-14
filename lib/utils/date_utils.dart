/// =======================================
/// 거래일자 정규화 (DB 저장용)
/// =======================================
/// 규칙:
/// - raw 값이 있으면 그것을 기준으로 정규화
///   • yyyyMMdd  → yyyy-MM-dd
///   • yyyy-MM-dd → 그대로
/// - raw 값이 없고 fallbackYear가 있으면 → YYYY-01-01
/// - 그 외는 ''
String normalizeDealDate(
    String? raw, {
      String? fallbackYear,
    }) {
  final v = (raw ?? '').trim();

  // 값이 없을 때: fallbackYear로 보정
  if (v.isEmpty) {
    final fy = (fallbackYear ?? '').trim();
    if (RegExp(r'^\d{4}$').hasMatch(fy)) {
      // ✅ 연도 시트(ex: "2024") → 최소 날짜로 보정 (정렬/검색용)
      return '$fy-01-01';
    }
    return '';
  }

  // yyyyMMdd → yyyy-MM-dd
  if (RegExp(r'^\d{8}$').hasMatch(v)) {
    return '${v.substring(0, 4)}-${v.substring(4, 6)}-${v.substring(6, 8)}';
  }

  // yyyy-MM-dd → 그대로
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
    return v;
  }

  // 그 외 포맷은 그대로 저장
  return v;
}

/// =======================================
/// 거래일자 표시용 (UI / Excel 출력)
/// =======================================
/// 규칙:
/// - DB에 저장된 값을 사람이 보기 좋게 표시
/// - 보정 ❌ (fallbackYear 사용 안 함)
String formatDealDate(String? raw) {
  if (raw == null) return '';

  final v = raw.trim();
  if (v.isEmpty) return '';

  // yyyyMMdd → yyyy-MM-dd
  if (RegExp(r'^\d{8}$').hasMatch(v)) {
    return '${v.substring(0, 4)}-${v.substring(4, 6)}-${v.substring(6, 8)}';
  }

  // yyyy-MM-dd → 그대로
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
    return v;
  }

  return v;
}
