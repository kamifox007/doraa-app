import 'package:flutter/material.dart';

class GoldenBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const GoldenBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
          child: const Center(
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFFFFD700),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
