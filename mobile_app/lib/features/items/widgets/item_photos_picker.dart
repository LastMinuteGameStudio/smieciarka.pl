import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

class ItemPhotosPicker extends StatelessWidget {
  const ItemPhotosPicker({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  static const maxPhotos = 8;
  static const _tileSize = 88.0;

  final List<XFile> photos;
  final ValueChanged<List<XFile>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zdjęcia (opcjonalnie, max $maxPhotos)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final photo in photos)
              _PhotoTile(
                photo: photo,
                onRemove: () =>
                    onChanged(photos.where((p) => p != photo).toList()),
              ),
            if (photos.length < maxPhotos) _AddPhotoTile(onTap: _pickPhotos),
          ],
        ),
      ],
    );
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      limit: maxPhotos - photos.length,
    );
    if (picked.isEmpty) {
      return;
    }
    onChanged([...photos, ...picked].take(maxPhotos).toList());
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onRemove});

  final XFile photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(photo.path),
            width: ItemPhotosPicker._tileSize,
            height: ItemPhotosPicker._tileSize,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: ColorPalette.titleColor,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: ColorPalette.yelowishWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: ItemPhotosPicker._tileSize,
        height: ItemPhotosPicker._tileSize,
        decoration: BoxDecoration(
          color: ColorPalette.yelowishWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorPalette.mainColor, width: 1.5),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: ColorPalette.mainColor,
          size: 32,
        ),
      ),
    );
  }
}
