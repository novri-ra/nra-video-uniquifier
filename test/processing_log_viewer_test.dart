import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/features/process/widgets/processing_log_viewer.dart';

void main() {
  group('ProcessingLogViewer Responsive & Truncation Tests', () {
    testWidgets('Handles extremely long filename (> 200 chars) without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const extremelyLongFileName =
          'ExtremelyLongFilename_2026_Enterprise_Camera_Pipeline_HighDefinition_Camera_Sensor_RAW_4K_Render_Stream_Output_Hash_98471928471982741982749182749182749182749182749182749182749182749182749182749182749182749182749182749.mp4';
      assert(extremelyLongFileName.length > 200);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: ProcessingLogViewer(
                  fileName: extremelyLongFileName,
                  duration: '02:45:12.890',
                  executionTime: '01:45s (4.2x speed)',
                  estimatedRemaining: '00:08s rem',
                  terminalLogs: '[INFO] Initializing hardware encoders...\n[INFO] Filter graph loaded successfully.\n[WARN] High entropy block detected, applying adaptive GOP.',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SOURCE'), findsOneWidget);
      expect(find.text('EXECUTION TIME'), findsOneWidget);
      expect(find.text('SANDBOX STATE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders on constrained 240px width without layout exceptions', (tester) async {
      tester.view.physicalSize = const Size(240, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: ProcessingLogViewer(
                  fileName: 'A_Very_Long_Filename_For_A_Small_Screen_Test_Case_Long_Long_Long_Long.mp4',
                  duration: '00:15',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SOURCE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
