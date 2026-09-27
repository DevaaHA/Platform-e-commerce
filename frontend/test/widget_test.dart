// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('SouqJo App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const SouqJoApp());

    // التحقق من حالة التطبيق وتوافق العناصر
    expect(find.text('سوق جو - SouqJo'), findsNothing);
  });
}
