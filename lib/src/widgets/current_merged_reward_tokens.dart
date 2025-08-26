import 'package:flutter/material.dart';

import '../../rewards.dart';

///widget that merges the current and max reward tokens
class CurrentMergedRewardTokens extends StatelessWidget {
  const CurrentMergedRewardTokens({
    super.key,
    this.textStyle,
    this.icon = Icons.lock_open,
    this.iconSize = 17,
    this.spacing = 3,
    this.iconColor,
  });

  final TextStyle? textStyle;
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: [
        Icon(icon, color: iconColor, size: iconSize),

        CurrentRewardTokens(
          tokenDisplayBuilder:
              (currentTokens) => Text(currentTokens, style: textStyle),
        ),
        Text("/"),
        MaxRewardTokens(
          maxRewardTokensDisplayBuilder:
              (maxTokens) => Text(maxTokens, style: textStyle),
        ),
      ],
    );
  }
}
