import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

class ItemImageCarousel extends StatelessWidget {
  const ItemImageCarousel({super.key, required this.imageUrls});

  static const _height = 280.0;

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return _Placeholder(height: _height);
    }

    final cardWidth = MediaQuery.sizeOf(context).width * 0.8;

    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) => SizedBox(
          width: cardWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _Placeholder(height: null),
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ColorPalette.yelowishWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.mainColor, width: 1.5),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: ColorPalette.mainColor,
          size: 48,
        ),
      ),
    );
  }
}
