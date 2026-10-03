import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_title.dart';

/// Standard page title, left-aligned. Shows a back button when the route
/// can be popped, so it replaces the AppBar on every screen.
class UCPageHeader extends StatelessWidget {
  const UCPageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (context.canPop())
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: ColorPalette.mainColor,
            ),
          ),
        Expanded(child: UCTitle(title: title)),
      ],
    );
  }
}
