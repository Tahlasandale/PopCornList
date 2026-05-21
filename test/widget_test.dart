import 'package:flutter_test/flutter_test.dart';
import 'package:films_app/app.dart';

void main() {
  testWidgets('App loads and shows navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const PopCornList());

    expect(find.text('Recherche'), findsOneWidget);
    expect(find.text('À regarder'), findsOneWidget);
    expect(find.text('Vus'), findsOneWidget);
  });
}
