import 'package:flutter_test/flutter_test.dart';
import 'package:uczciwa_cena/app/app.dart';
import 'package:uczciwa_cena/features/welcome/welcome_screen.dart';

void main() {
  testWidgets('app starts on the welcome screen', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
