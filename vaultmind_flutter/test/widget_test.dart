import 'package:flutter_test/flutter_test.dart';
import 'package:vaultmind/main.dart';

void main() {
  testWidgets('VaultMind app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VaultMindApp());

    // Verify that the splash screen is shown initially
    expect(find.text('VaultMind'), findsOneWidget);
    expect(find.text('Privacy-Focused AI Assistant'), findsOneWidget);
  });
}