import 'package:flutter/material.dart';
import '../../../theme.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.brandRedAlt,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: AppDecorations.statCardDecoration(color),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.smallLabel.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.statsValue.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
