import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({
    super.key,
    required this.method,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final String method;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = _PaymentMethodStyle.fromMethod(method);
    final foreground = selected ? Colors.white : style.color;
    final background = selected ? style.color : style.lightColor;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? style.color : style.color.withValues(alpha: 0.24),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 22 : 28,
            height: compact ? 22 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  selected ? Colors.white.withValues(alpha: 0.18) : style.color,
              shape: BoxShape.circle,
            ),
            child: Text(
              style.mark,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(
              method,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: child,
    );
  }
}

class _PaymentMethodStyle {
  const _PaymentMethodStyle({
    required this.mark,
    required this.color,
    required this.lightColor,
  });

  final String mark;
  final Color color;
  final Color lightColor;

  static _PaymentMethodStyle fromMethod(String method) {
    return switch (method) {
      'Wave' => const _PaymentMethodStyle(
          mark: 'W',
          color: Color(0xFF1D9BF0),
          lightColor: Color(0xFFE7F4FF),
        ),
      'Orange Money' => const _PaymentMethodStyle(
          mark: 'OM',
          color: Color(0xFFFF7900),
          lightColor: Color(0xFFFFF1E5),
        ),
      'Free Money' => const _PaymentMethodStyle(
          mark: 'FM',
          color: Color(0xFFE30613),
          lightColor: Color(0xFFFFE8EA),
        ),
      'Wizall' => const _PaymentMethodStyle(
          mark: 'WZ',
          color: Color(0xFF00A676),
          lightColor: Color(0xFFE3F7F0),
        ),
      _ => const _PaymentMethodStyle(
          mark: 'C',
          color: AppColors.primary,
          lightColor: AppColors.primarySoft,
        ),
    };
  }
}
