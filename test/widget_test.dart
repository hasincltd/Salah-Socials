import 'package:flutter_test/flutter_test.dart';
import 'package:salah_socials/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SalahSocialsApp());
    expect(find.text('Salah Socials'), findsOneWidget);
  });
}
