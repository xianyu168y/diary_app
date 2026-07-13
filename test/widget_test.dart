import 'package:flutter_test/flutter_test.dart';
import 'package:diary/main.dart';
import 'package:diary/services/theme_provider.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await tester.pumpWidget(DiaryApp(themeProvider: themeProvider));
    expect(find.text('📖 我的日记'), findsOneWidget);
  });
}