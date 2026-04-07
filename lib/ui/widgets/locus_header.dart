import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LocusHeader extends StatelessWidget {
  final Widget leftIcon;
  final Widget? rightIcon1;
  final Widget? rightIcon2;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRight1Tap;
  final VoidCallback? onRight2Tap;

  const LocusHeader({
    Key? key,
    required this.leftIcon,
    this.rightIcon1,
    this.rightIcon2,
    this.onLeftTap,
    this.onRight1Tap,
    this.onRight2Tap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = context.appColors.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: leftIcon,
            onPressed: onLeftTap,
            color: iconColor,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rightIcon1 != null) ...[
                IconButton(
                  icon: rightIcon1!,
                  onPressed: onRight1Tap,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
              ],
              if (rightIcon2 != null)
                IconButton(
                  icon: rightIcon2!,
                  onPressed: onRight2Tap,
                  color: iconColor,
                ),
            ],
          )
        ],
      ),
    );
  }
}
