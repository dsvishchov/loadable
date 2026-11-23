import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart' show
  CupertinoActivityIndicator, CupertinoSliverRefreshControl;
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

  testWidgets('fixed content preserves its own scroll view', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          builder: (_) => (_) => ListView.builder(
            itemCount: 40,
            itemBuilder: (_, index) => SizedBox(
              height: 80,
              child: Text('Item $index'),
            ),
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Item 39'),
      500,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );

    expect(find.text('Item 39'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets(
      'Cupertino refresh stays gated for a gesture starting away from the top',
      (tester) async {
        final controller = ScrollController(
          initialScrollOffset: 400,
        );
        final refresh = Completer<void>();
        var calls = 0;
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: LoadableScaffold(
              bodyLayout: .slivers,
              refreshIndicatorStyle: .cupertino,
              scrollController: controller,
              onRefresh: () {
                calls++;
                return refresh.future;
              },
              builder: (_) => (_) => SliverList.builder(
                itemCount: 50,
                itemBuilder: (_, index) => SizedBox(
                  height: 80,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        );

        final view = find.byType(CustomScrollView);
        final gesture = await tester.startGesture(tester.getCenter(view));
        await gesture.moveBy(const Offset(0, 100));
        await tester.pump();

        expect(
          find.byType(
            CupertinoSliverRefreshControl,
            skipOffstage: false,
          ),
          findsNothing,
        );

        await gesture.moveBy(const Offset(0, 700));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(calls, 0);
        expect(controller.offset, closeTo(0, 0.1));

        final pull = await tester.startGesture(tester.getCenter(view));
        await pull.moveBy(const Offset(0, 20));
        await tester.pump();
        await pull.moveBy(const Offset(0, 400));
        await tester.pump();
        await pull.up();
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

  testWidgets('default loading keeps its original appearance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          statusBuilder: () => .loading,
        ),
      ),
    );

    final finder = find.byType(CupertinoActivityIndicator);
    final indicator = tester.widget<CupertinoActivityIndicator>(finder);
    expect(indicator.radius, 14);
    expect(indicator.color, Colors.black);
    expect(tester.getTopLeft(finder).dy, 16);
  });

  testWidgets('default error keeps its original message and layout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadableScaffold(
          statusBuilder: () => .error,
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(
      find.text('We have been notified and will do our best to resolve the problem as soon as possible'),
      findsOneWidget,
    );
    expect(
      tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor,
      0.85,
    );
  });

  for (final layout in LoadableAppBarLayout.values) {
    testWidgets('app bar layout $layout is independent of the sliver body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadableScaffold(
            bodyLayout: .slivers,
            appBarLayout: layout,
            appBarBuilder: (_) => (_) => layout == .fixed
              ? AppBar(
                  title: const Text('Page title'),
                )
              : const SliverAppBar(
                  title: Text('Page title'),
                ),
            builder: (_) => (_) => SliverList.builder(
              itemCount: 50,
              itemBuilder: (_, index) => SizedBox(
                height: 80,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Page title').hitTestable(), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(
        find.text('Page title').hitTestable(),
        layout == .fixed ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

}
