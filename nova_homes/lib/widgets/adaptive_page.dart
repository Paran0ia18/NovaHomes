import 'package:flutter/material.dart';

class AdaptivePage extends StatelessWidget {
  const AdaptivePage({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double targetMaxWidth =
        maxWidth ??
        (width >= 1200
            ? 920
            : width >= 900
            ? 760
            : width >= 700
            ? 640
            : width);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: targetMaxWidth),
        child: child,
      ),
    );
  }
}
