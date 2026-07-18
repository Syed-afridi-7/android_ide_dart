import 'package:flutter_test/flutter_test.dart';
import 'package:android_ide/app/app.dart';

void main() {
  testWidgets('IDE Smoke Test - Renders Projects screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title "Android IDE" is rendered on the startup screen.
    expect(find.text('Android IDE'), findsOneWidget);
    expect(find.text('Open Local Folder'), findsOneWidget);
  });
}
