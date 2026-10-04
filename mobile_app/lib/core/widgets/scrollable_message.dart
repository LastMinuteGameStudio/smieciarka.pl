import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

/// A centred message or spinner that still scrolls, so pull-to-refresh works
/// on it even when the list is empty.
class ScrollableMessage extends StatelessWidget {
  const ScrollableMessage({super.key, this.text, this.child});

  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child:
                    child ??
                    Text(
                      text ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ColorPalette.descColor),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
