import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uczciwa_cena/app/app.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/features/welcome/welcome_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUp(() {
    final auth = MockAuthRepository();
    when(() => auth.restoreSession()).thenAnswer((_) async => false);
    GetIt.instance.registerSingleton<AuthRepository>(auth);
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('app starts on the welcome screen without a session', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
