import 'package:flutter/material.dart';

/// Draws the drop shadow shared by all UC buttons.
class UCButtonShadow extends StatelessWidget {
  const UCButtonShadow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
