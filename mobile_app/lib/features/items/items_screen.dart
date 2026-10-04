import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/location/user_location.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/scrollable_message.dart';
import 'package:uczciwa_cena/core/widgets/search_add_bar.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/items/data/listings_repository.dart';
import 'package:uczciwa_cena/features/items/widgets/item_tile.dart';
import 'package:uczciwa_cena/models/item.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  static const _debounce = Duration(milliseconds: 400);

  final _repository = GetIt.instance<ListingsRepository>();
  late final Future<LatLng> _location = currentLocationOr(warsawCenter);

  Timer? _timer;
  String _query = '';
  late Future<List<Item>> _items = _search(_query);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<Item>> _search(String query) async {
    return _repository.search(query, await _location);
  }

  void _onQueryChanged(String query) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) {
        setState(() {
          _query = query;
          _items = _search(query);
        });
      }
    });
  }

  /// Reloads the current search. Errors are shown by the list itself.
  Future<void> _refresh() async {
    final future = _search(_query);
    setState(() => _items = future);
    await future.catchError((_) => <Item>[]);
  }

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
                Expanded(child: _buildList()),
                const SizedBox(height: 24),
                SearchAddBar(
                  hintText: 'Szukaj ogłoszeń',
                  onChanged: _onQueryChanged,
                  onAddPressed: () => context.push(AppRoutes.newItem),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: ColorPalette.mainColor,
      onRefresh: _refresh,
      child: FutureBuilder<List<Item>>(
        future: _items,
        builder: (context, snapshot) {
          final items = snapshot.data;
          if (items != null) {
            if (items.isEmpty) {
              return const ScrollableMessage(text: 'Brak wyników');
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (_, index) => ItemTile(item: items[index]),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
            );
          }
          if (snapshot.hasError) {
            return const ScrollableMessage(
              text: 'Nie udało się pobrać ogłoszeń. Przeciągnij, aby spróbować ponownie.',
            );
          }
          return const ScrollableMessage(
            child: CircularProgressIndicator(color: ColorPalette.mainColor),
          );
        },
      ),
    );
  }
}
