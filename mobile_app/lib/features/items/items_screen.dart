import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/search_add_bar.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/items/widgets/item_tile.dart';
import 'package:uczciwa_cena/models/item.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  // TODO: replace with items from the backend.
  static const _items = [
    Item(
      id: '1',
      name: 'Krzesło drewniane',
      description: 'Stare, ale solidne krzesło. Lekko zarysowane z tyłu.',
      phoneNumber: '123 456 789',
      pickupLocation: 'Warszawa, Mokotów',
    ),
    Item(
      id: '2',
      name: 'Stół kuchenny',
      description:
          'Stół 120 x 80 cm, do rozłożenia. Odbiór po wcześniejszym kontakcie.',
      phoneNumber: '987 654 321',
    ),
    Item(
      id: '3',
      name: 'Lampa biurkowa',
      description: 'Sprawna, bez uszkodzeń. Kabel w dobrym stanie.',
      phoneNumber: '555 111 222',
      pickupLocation: 'Kraków, Podgórze',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UCPageHeader(title: 'Ogłoszenia'),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    itemBuilder: (_, index) => ItemTile(item: _items[index]),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                  ),
                ),
                const SizedBox(height: 24),
                SearchAddBar(
                  hintText: 'Szukaj ogłoszeń',
                  onAddPressed: () => context.push(AppRoutes.newItem),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
