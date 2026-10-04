import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/location/user_location.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/scrollable_message.dart';
import 'package:uczciwa_cena/core/widgets/search_add_bar.dart';
import 'package:uczciwa_cena/core/widgets/uc_add_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_button_shadow.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/items/data/listings_repository.dart';
import 'package:uczciwa_cena/features/items/widgets/item_filters_sheet.dart';
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
  bool _mineOnly = false;
  String _query = '';
  late Future<List<Item>> _items = _search(_query);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<Item>> _search(String query) async {
    return _repository.search(query, await _location, mine: _mineOnly);
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

  /// Opens the new-listing form. Adding a listing needs a session, so without
  /// one the user gets a message with a shortcut to log in.
  Future<void> _openNewItem() async {
    final loggedIn = await GetIt.instance<AuthRepository>().hasStoredSession();
    if (!mounted) {
      return;
    }
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zaloguj się, aby dodać ogłoszenie.'),
          action: SnackBarAction(
            label: 'Zaloguj',
            onPressed: () => context.push(AppRoutes.login),
          ),
        ),
      );
      return;
    }
    context.push(AppRoutes.newItem);
  }

  Future<void> _openFilters() async {
    final mineOnly = await showItemFiltersSheet(context, mineOnly: _mineOnly);
    if (mineOnly == null || mineOnly == _mineOnly || !mounted) {
      return;
    }
    final loggedIn = await GetIt.instance<AuthRepository>().hasStoredSession();
    if (!mounted) {
      return;
    }
    if (mineOnly && !loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zaloguj się, aby zobaczyć swoje ogłoszenia.'),
          action: SnackBarAction(
            label: 'Zaloguj',
            onPressed: () => context.push(AppRoutes.login),
          ),
        ),
      );
      return;
    }
    setState(() {
      _mineOnly = mineOnly;
      _items = _search(_query);
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
                Row(
                  children: [
                    UCButtonShadow(
                      child: Expanded(
                        child: SizedBox(
                          height: 56,

                          child: ElevatedButton.icon(
                            onPressed: _openFilters,
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('Filtry'),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: ColorPalette.mainColor,
                              foregroundColor: ColorPalette.yelowishWhite,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    UCAddButton(onPressed: _openNewItem),
                  ],
                ),
                const SizedBox(height: 12),
                SearchAddBar(
                  hintText: 'Szukaj ogłoszeń',
                  onChanged: _onQueryChanged,
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
