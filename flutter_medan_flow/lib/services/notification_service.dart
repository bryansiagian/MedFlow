import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    // Tidak perlu setup apapun
  }

  static void showCongestionAlert({
    required BuildContext context,
    required String roadName,
    required String level,
  }) {
    final emoji = level == 'sangat_macet' ? '🔴'
        : level == 'macet' ? '🟠' : '🟡';
    final status = level == 'sangat_macet' ? 'Sangat Macet'
        : level == 'macet' ? 'Macet Parah' : 'Padat Merayap';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji $roadName: $status'),
        backgroundColor: level == 'sangat_macet' ? const Color(0xFF7B0000)
            : level == 'macet' ? Colors.red
            : Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}