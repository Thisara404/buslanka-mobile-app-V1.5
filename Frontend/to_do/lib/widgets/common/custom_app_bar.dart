import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 4.0,
    this.flexibleSpace,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading ??
          (onBackPressed != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBackPressed,
                )
              : null),
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: foregroundColor,
      elevation: elevation,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => bottom == null
      ? Size.fromHeight(kToolbarHeight)
      : Size.fromHeight(kToolbarHeight + bottom!.preferredSize.height);
}
