import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/core/theme.dart';
import 'package:weft_mobile/core/widgets/widgets.dart';
import 'package:weft_mobile/data/models/enums.dart';
import 'package:weft_mobile/features/report/state/report_draft.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: WeftTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('StatusBadge: label + distinct icon per status, a11y label', (
    tester,
  ) async {
    final icons = <IconData>{};
    for (final s in IssueStatus.values) {
      await tester.pumpWidget(_wrap(StatusBadge(s)));
      expect(find.text(s.visual.label), findsOneWidget);
      expect(
        find.bySemanticsLabel('Status: ${s.visual.label}'),
        findsOneWidget,
      );
      icons.add(s.visual.icon);
    }
    expect(
      icons.length,
      IssueStatus.values.length,
      reason: 'status must never be conveyed by colour alone',
    );
  });

  test('every category has a distinct label, icon and colour', () {
    final v = IssueCategory.values.map((c) => c.visual).toList();
    expect(v.map((x) => x.label).toSet().length, IssueCategory.values.length);
    expect(v.map((x) => x.icon).toSet().length, IssueCategory.values.length);
    expect(v.map((x) => x.color).toSet().length, IssueCategory.values.length);
  });

  testWidgets('CategoryIcon is labelled for screen readers', (tester) async {
    await tester.pumpWidget(_wrap(const CategoryIcon(IssueCategory.pothole)));
    expect(find.bySemanticsLabel('Pothole'), findsOneWidget);
  });

  testWidgets('WeftPrimaryButton: loading disables taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        WeftPrimaryButton(
          label: 'Submit',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ErrorView retry is reachable', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _wrap(ErrorView(message: 'Boom', onRetry: () => retries++)),
    );
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  test('ReportDraft builds the POST /issues input', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final draft = container.read(reportDraftProvider.notifier)
      ..setPhotos(['/tmp/a.jpg'])
      ..setCategory(IssueCategory.waterLogging)
      ..setLocation(latitude: 13.1, longitude: 80.2, addressText: 'Adyar')
      ..setDescription('  Flooded underpass  ');
    final state = container.read(reportDraftProvider);
    expect(state.isReadyToSubmit, isTrue);
    final input = state.toInput(captchaToken: 'c');
    expect(input.category, IssueCategory.waterLogging);
    expect(input.description, 'Flooded underpass');
    expect(input.images.single.path, '/tmp/a.jpg');
    expect(input.captchaToken, 'c');
    draft.reset();
    expect(container.read(reportDraftProvider).isReadyToSubmit, isFalse);
  });
}
