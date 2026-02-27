import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A button that renders as [CupertinoButton.filled] on Apple platforms
/// and [ElevatedButton] on other platforms.
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        padding: padding,
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  child,
                ],
              )
            : child,
      );
    }

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style:
            padding != null ? ElevatedButton.styleFrom(padding: padding) : null,
        icon: icon!,
        label: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style:
          padding != null ? ElevatedButton.styleFrom(padding: padding) : null,
      child: child,
    );
  }
}
