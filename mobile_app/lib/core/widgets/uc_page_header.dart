import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_title.dart';

/// Standard page title, left-aligned. Replaces the AppBar on every screen.
///
/// Shows a back button when the route can be popped, unless [showBack] is
/// false. Android's system back gesture still works either way.
class UCPageHeader extends StatelessWidget {
  const UCPageHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.trailing,
  });

  final String title;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack && context.canPop())
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: ColorPalette.mainColor,
            ),
          ),
        Expanded(child: UCTitle(title: title)),
        ?trailing,
      ],
    );
  }
}
