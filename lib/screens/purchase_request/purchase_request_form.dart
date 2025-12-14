// lib/screens/purchase_request/purchase_request_form.dart
import 'package:flutter/material.dart';
import '../../utils/date_utils.dart';

/// ===============================================
///  발주서(견적요청) 상단 헤더 폼
///  - 거래처 / 담당자 / 발주일 / 비고
///  - 상태는 Screen에서 관리 (Controller 주입)
/// ===============================================
class PurchaseRequestForm extends StatelessWidget {
  final TextEditingController vendorCtrl;
  final TextEditingController managerCtrl;
  final TextEditingController memoCtrl;

  const PurchaseRequestForm({
    super.key,
    required this.vendorCtrl,
    required this.managerCtrl,
    required this.memoCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final today = formatDealDate(
      DateTime.now().toIso8601String(),
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===============================
          //  1열: 발주번호 / 발주일
          // ===============================
          Row(
            children: [
              _labelBox('발주번호', '자동 생성'),
              const SizedBox(width: 12),
              _labelBox('발주일자', today),
            ],
          ),

          const SizedBox(height: 12),

          // ===============================
          //  2열: 거래처 / 담당자
          // ===============================
          Row(
            children: [
              Expanded(
                child: _inputBox(
                  label: '거래처',
                  controller: vendorCtrl,
                  hint: '선택 또는 직접 입력',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputBox(
                  label: '담당자',
                  controller: managerCtrl,
                  hint: '담당자 이름',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===============================
          //  비고
          // ===============================
          _inputBox(
            label: '비고',
            controller: memoCtrl,
            hint: '요청 사항을 입력하세요',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ======================================================
  //  공통 UI 컴포넌트
  // ======================================================

  Widget _labelBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                )),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            )),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}
