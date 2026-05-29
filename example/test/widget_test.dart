import 'package:flutter_test/flutter_test.dart';

import 'package:social_story_share_example/main.dart';

void main() {
  testWidgets('Example app renders Share button', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(
      find.text('Share demo image to Instagram Story'),
      findsOneWidget,
    );
  });
}
