import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/scrollable_message.dart';
import 'package:uczciwa_cena/core/widgets/search_add_bar.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/alerts/data/alerts_repository.dart';
import 'package:uczciwa_cena/features/alerts/widgets/alert_tile.dart';
import 'package:uczciwa_cena/models/alert.dart';

/// The signed-in user's alerts. Without a session it asks the user to log in.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _auth = GetIt.instance<AuthRepository>();
  final _repository = GetIt.instance<AlertsRepository>();

  bool _checked = false;
  bool _loggedIn = false;
  String _query = '';
  Future<List<Alert>> _alerts = Future.value(const <Alert>[]);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Re-checks the session and reloads alerts. Also used by pull-to-refresh.
  Future<void> _refresh() async {
    final loggedIn = await _auth.hasStoredSession();
    if (!mounted) {
      return;
    }
    final alerts = loggedIn
        ? _repository.list()
        : Future.value(const <Alert>[]);
    setState(() {
      _checked = true;
      _loggedIn = loggedIn;
      _alerts = alerts;
    });
    await alerts.catchError((_) => <Alert>[]);
  }

  Future<void> _openNewAlert() async {
    await context.push(AppRoutes.newAlert);
    if (mounted) {
      await _refresh();
    }
  }

  List<Alert> _matching(List<Alert> alerts) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return alerts;
    }
    return alerts
        .where(
          (alert) =>
              alert.name.toLowerCase().contains(query) ||
              alert.description.toLowerCase().contains(query),
        )
        .toList();
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
                const UCPageHeader(title: 'Alerty'),
                const SizedBox(height: 24),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_checked) {
      return const Center(
        child: CircularProgressIndicator(color: ColorPalette.mainColor),
      );
    }
    if (!_loggedIn) {
      return const _LoginPrompt();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildList()),
        const SizedBox(height: 24),
        SearchAddBar(
          hintText: 'Szukaj alertów',
          onChanged: (query) => setState(() => _query = query),
          onAddPressed: _openNewAlert,
        ),
      ],
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: ColorPalette.mainColor,
      onRefresh: _refresh,
      child: FutureBuilder<List<Alert>>(
        future: _alerts,
        builder: (context, snapshot) {
          final alerts = snapshot.data;
          if (alerts != null) {
            final matching = _matching(alerts);
            if (matching.isEmpty) {
              return const ScrollableMessage(text: 'Brak wyników');
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: matching.length,
              itemBuilder: (_, index) => AlertTile(alert: matching[index]),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
            );
          }
          if (snapshot.hasError) {
            return const ScrollableMessage(
              text: 'Nie udało się pobrać alertów. Przeciągnij, aby spróbować ponownie.',
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

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Zaloguj się, aby zobaczyć i tworzyć alerty.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: ColorPalette.descColor),
        ),
        const SizedBox(height: 24),
        UCButton(
          label: 'Zaloguj się',
          onPressed: () => context.push(AppRoutes.login),
        ),
      ],
    );
  }
}
