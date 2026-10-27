import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nra_video_uniquifier/main.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';

void main() {
  testWidgets('Video Uniquifier UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UniquifierProvider()),
        ],
        child: const VideoUniquifierApp(),
      ),
    );

    expect(find.text('VIDEO UNIQUIFIER'), findsWidgets);
    expect(find.text('Process'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);
    expect(find.text('Inspect'), findsOneWidget);
  });
}
