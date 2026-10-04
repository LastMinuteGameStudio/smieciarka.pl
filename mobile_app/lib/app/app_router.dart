import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/features/alerts/alert_screen.dart';
import 'package:uczciwa_cena/features/alerts/alerts_screen.dart';
import 'package:uczciwa_cena/features/alerts/new_alert_screen.dart';
import 'package:uczciwa_cena/features/auth/login_screen.dart';
import 'package:uczciwa_cena/features/items/item_screen.dart';
import 'package:uczciwa_cena/features/items/items_screen.dart';
import 'package:uczciwa_cena/features/items/new_item_screen.dart';
import 'package:uczciwa_cena/features/profile/profile_screen.dart';
import 'package:uczciwa_cena/features/splash/splash_screen.dart';
import 'package:uczciwa_cena/features/welcome/welcome_screen.dart';
import 'package:uczciwa_cena/models/alert.dart';
import 'package:uczciwa_cena/models/item.dart';
import 'package:uczciwa_cena/shell/main_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.items,
              builder: (_, _) => const ItemsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.alerts,
              builder: (_, _) => const AlertsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.item,
      builder: (_, state) => ItemScreen(item: state.extra as Item),
    ),
    GoRoute(
      path: AppRoutes.alert,
      builder: (_, state) => AlertScreen(alert: state.extra as Alert),
    ),
    GoRoute(path: AppRoutes.newItem, builder: (_, _) => const NewItemScreen()),
    GoRoute(
      path: AppRoutes.newAlert,
      builder: (_, _) => const NewAlertScreen(),
    ),
  ],
);
