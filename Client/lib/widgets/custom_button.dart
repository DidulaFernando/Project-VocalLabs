// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final IconData? icon;
  final double width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.icon,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? AppColors.primaryBlue;
    final txtColor = textColor ?? (isOutlined ? color : Colors.white);

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: txtColor,
          elevation: isOutlined ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: isOutlined ? BorderSide(color: color) : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(text, style: AppTextStyles.button.copyWith(color: txtColor)),
          ],
        ),
      ),
    );
  }
}
