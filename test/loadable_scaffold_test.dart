import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadable/loadable.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    LoadableScaffold.useAdaptiveIndicator = true;
  });

  testWidgets('short content fills the viewport and supports Spacer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          bodyLayout: .scrollable,
          builder: (_) => (_) => const Column(
            children: [
              Text('Top'),
              Spacer(),
              Text('Bottom'),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getBottomLeft(find.text('Bottom')).dy, 600);
  });

  testWidgets('tall forms scroll when the keyboard reduces the viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          bodyLayout: .scrollable,
          keyboardDismissBehavior: .onDrag,
          builder: (_) => (_) => Column(
            children: [
              const SizedBox(
                height: 500,
              ),
              TextButton(
                onPressed: () => submitted = true,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );

    tester.view.viewInsets = const FakeViewPadding(
      bottom: 300,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    expect(submitted, isTrue);
  });

  testWidgets('fixed content leaves scrolling to its child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          builder: (_) => (_) => const Text('Fixed'),
        ),
      ),
    );

    expect(find.byType(CustomScrollView), findsNothing);
    expect(find.text('Fixed'), findsOneWidget);
  });

  testWidgets('sliver lists stay lazy and can reach distant items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          bodyLayout: .slivers,
          builder: (_) => (_) => SliverList.builder(
            itemCount: 100,
            itemBuilder: (_, index) => SizedBox(
              height: 80,
              child: Text('Item $index'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Item 99'), findsNothing);
    await tester.scrollUntilVisible(find.text('Item 99'), 500);
    expect(find.text('Item 99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets('Cupertino refresh works on $platform', (tester) async {
      final refresh = Completer<void>();
      var calls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: LoadableScaffold(
            bodyLayout: .scrollable,
            refreshIndicatorStyle: .cupertino,
            onRefresh: () {
              calls++;
              return refresh.future;
            },
            builder: (_) => (_) => const Text('Content'),
          ),
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pump(
        const Duration(
          seconds: 1,
        ),
      );
      expect(calls, 1);
      refresh.complete();
      await tester.pumpAndSettle();
    },
      variant: TargetPlatformVariant({platform}),
    );
  }

  testWidgets('Material refresh works with content shorter than the viewport', (tester) async {
    final refresh = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          bodyLayout: .scrollable,
          refreshIndicatorStyle: .material,
          onRefresh: () {
            calls++;
            return refresh.future;
          },
          builder: (_) => (_) => const Text('Content'),
        ),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(
      const Duration(
        seconds: 1,
      ),
    );
    expect(calls, 1);
    refresh.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('legacy setting still forces Cupertino on Android', (tester) async {
    LoadableScaffold.useAdaptiveIndicator = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          bodyLayout: .scrollable,
          onRefresh: () async {},
          builder: (_) => (_) => const Text('Content'),
        ),
      ),
    );

    expect(find.byType(
      CupertinoSliverRefreshControl,
      skipOffstage: false,
    ), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('loading and errors stay bounded in sliver mode', (tester) async {
    final loading = LoadableScaffold.defaultLoadingWidget;
    final error = LoadableScaffold.defaultErrorWidget;
    addTearDown(() {
      LoadableScaffold.defaultLoadingWidget = loading;
      LoadableScaffold.defaultErrorWidget = error;
    });
    LoadableScaffold.defaultLoadingWidget = const Text('Loading');
    LoadableScaffold.defaultErrorWidget = const Text('Error');

    for (final status in [
      LoadableStatus.loading,
      LoadableStatus.error,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadableScaffold(
            bodyLayout: .slivers,
            statusBuilder: () => status,
            builder: (status) => status.when(
              loaded: (_) => const SliverToBoxAdapter(
                child: Text('Loaded'),
              ),
            ),
          ),
        ),
      );

      expect(find.text(status.isLoading ? 'Loading' : 'Error'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
