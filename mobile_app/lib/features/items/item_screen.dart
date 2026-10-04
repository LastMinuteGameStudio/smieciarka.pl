import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/utils/native_maps.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/items/widgets/contact_sheet.dart';
import 'package:uczciwa_cena/features/items/widgets/item_image_carousel.dart';
import 'package:uczciwa_cena/models/item.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemScreen extends StatelessWidget {
  const ItemScreen({super.key, required this.item});

  final Item item;

  Future<void> _openPickupLocation(
    BuildContext context,
    String location,
  ) async {
    final launched = await launchUrl(
      nativeMapsUri(location),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się otworzyć mapy')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupLocation = item.pickupLocation;
    final phone = item.phoneNumber;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: phone == null
            ? null
            : () => showContactSheet(context, phone),
        backgroundColor: ColorPalette.mainColor,
        foregroundColor: ColorPalette.yelowishWhite,
        icon: const Icon(Icons.phone_rounded),
        label: const Text('Kontakt'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UCPageHeader(title: 'Opis przedmiotu', showBack: false),
              const SizedBox(height: 24),
              ItemImageCarousel(imageUrls: item.imageUrls),
              const SizedBox(height: 24),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ColorPalette.titleColor,
                ),
              ),
              if (pickupLocation != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openPickupLocation(context, pickupLocation),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: ColorPalette.mainColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickupLocation,
                          style: const TextStyle(
                            fontSize: 18,
                            color: ColorPalette.mainColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 18,
                  color: ColorPalette.descColor,
                ),
              ),
              // Keeps the description clear of the floating button.
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
