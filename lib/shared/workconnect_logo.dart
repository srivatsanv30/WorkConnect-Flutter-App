import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class WorkConnectLogo extends StatelessWidget {
  final double size;
  const WorkConnectLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppTheme.logoGradient,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.55),
        ),
        const SizedBox(width: 10),
        Text(
          'WorkConnect',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
