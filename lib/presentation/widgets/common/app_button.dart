import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String    label;
  final VoidCallback? onPressed;
  final bool      isFullWidth;
  final bool      isOutlined;
  final bool      isLoading;
  final IconData? icon;
  final Color?    backgroundColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth  = false,
    this.isOutlined   = false,
    this.isLoading    = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(onPressed: isLoading ? null : onPressed, child: child)
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: backgroundColor != null
                ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
                : null,
            child: child,
          );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
