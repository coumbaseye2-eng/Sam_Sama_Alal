import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 68});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.48,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
