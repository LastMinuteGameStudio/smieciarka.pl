import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/scrollable_message.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/models/user_profile.dart';

/// Profile of the signed-in user. Without a session it asks the user to log in.
/// The phone number is shown but can't be changed. The subscription is a flag
/// on the backend that the button switches on and off.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = GetIt.instance<AuthRepository>();

  bool _checked = false;
  bool _loggedIn = false;
  bool _loadFailed = false;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Re-checks the session and loads the profile. Also used by pull-to-refresh.
  Future<void> _refresh() async {
    final loggedIn = await _auth.hasStoredSession();
    UserProfile? profile;
    var loadFailed = false;
    if (loggedIn) {
      try {
        profile = await _auth.fetchProfile();
      } on DioException {
        loadFailed = true;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _checked = true;
      _loggedIn = loggedIn;
      _loadFailed = loadFailed;
      _profile = profile;
    });
  }

  Future<void> _toggleSubscription() async {
    final current = _profile;
    if (current == null) {
      return;
    }
    try {
      final updated = await _auth.setSubscribed(!current.isSubscribed);
      if (mounted) {
        setState(() => _profile = updated);
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się zmienić subskrypcji')),
        );
      }
    }
  }

  /// Clears the session and stays on the profile, which switches to the
  /// logged-out view with a login prompt.
  Future<void> _logout() async {
    await _auth.logout();
    await _refresh();
  }

  /// The backend returns `+48…`, the form shows the local part only.
  static String _localDigits(String phone) {
    return phone.startsWith('+48') ? phone.substring(3) : phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UCPageHeader(title: 'Profil'),
              const SizedBox(height: 24),
              Expanded(child: _buildBody()),
            ],
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
    final profile = _profile;
    if (_loadFailed || profile == null) {
      return RefreshIndicator(
        color: ColorPalette.mainColor,
        onRefresh: _refresh,
        child: const ScrollableMessage(
          text: 'Nie udało się pobrać profilu. Przeciągnij, aby spróbować ponownie.',
        ),
      );
    }

    return RefreshIndicator(
      color: ColorPalette.mainColor,
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: ValueKey(profile.phoneNumber),
                  initialValue: _localDigits(profile.phoneNumber),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Nr telefonu',
                    prefixText: '+48 ',
                    suffixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
                if (profile.isSubscribed)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Subskrypcja jest aktywna',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorPalette.descColor,
                      ),
                    ),
                  ),
                UCButton(
                  label: profile.isSubscribed
                      ? 'Anuluj subskrypcję'
                      : 'Kup subskrypcję',
                  onPressed: _toggleSubscription,
                ),
                const SizedBox(height: 16),
                UCButton(
                  label: 'Wyloguj się',
                  backgroundColor: Theme.of(context).colorScheme.error,
                  onPressed: _logout,
                ),
              ],
            ),
          ),
        ),
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
          'Zaloguj się, aby zobaczyć swój profil.',
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
