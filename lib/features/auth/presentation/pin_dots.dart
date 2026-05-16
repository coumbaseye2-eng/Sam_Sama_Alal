import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, this.hasError = false});

  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final active = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? hasError
                    ? AppColors.danger
                    : AppColors.primary
                : AppColors.border,
          ),
        );
      }),
    );
  }
}
