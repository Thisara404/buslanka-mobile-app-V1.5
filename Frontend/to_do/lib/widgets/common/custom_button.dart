import 'package:flutter/material.dart';

enum ButtonType { primary, secondary, outline, text }

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderRadius = 8.0,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine button styling based on type
    final theme = Theme.of(context);

    // Default color scheme
    Color bgColor = backgroundColor ?? theme.colorScheme.primary;
    Color txtColor = textColor ?? theme.colorScheme.onPrimary;

    // Adjust based on type
    switch (type) {
      case ButtonType.primary:
        // Use defaults
        break;
      case ButtonType.secondary:
        bgColor = backgroundColor ?? theme.colorScheme.secondary;
        txtColor = textColor ?? theme.colorScheme.onSecondary;
        break;
      case ButtonType.outline:
        bgColor = backgroundColor ?? Colors.transparent;
        txtColor = textColor ?? theme.colorScheme.primary;
        break;
      case ButtonType.text:
        bgColor = backgroundColor ?? Colors.transparent;
        txtColor = textColor ?? theme.colorScheme.primary;
        break;
    }

    // Determine padding based on size
    EdgeInsetsGeometry padding;
    double textSize;

    switch (size) {
      case ButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        textSize = 14;
        break;
      case ButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        textSize = 16;
        break;
      case ButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        textSize = 18;
        break;
    }

    // Create button based on type
    Widget button;

    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: txtColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding,
          ),
          child: _buildButtonContent(txtColor, textSize),
        );
        break;
      case ButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: txtColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            side: BorderSide(color: txtColor),
            padding: padding,
          ),
          child: _buildButtonContent(txtColor, textSize),
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: txtColor,
            padding: padding,
          ),
          child: _buildButtonContent(txtColor, textSize),
        );
        break;
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildButtonContent(Color color, double textSize) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: textSize + 4),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: textSize)),
        ],
      );
    }

    return Text(text, style: TextStyle(fontSize: textSize));
  }
}
