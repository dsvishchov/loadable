import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart' show
  CupertinoActivityIndicator, CupertinoSliverRefreshControl;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '/src/loadable.dart';

enum LoadableBodyLayout {
  fixed,
  scrollable,
  slivers,
}

enum LoadableAppBarLayout {
  fixed,
  sliver,
}

enum RefreshIndicatorStyle {
  cupertino,
  material,
  adaptive,
}

/// Builds page chrome and content from a [LoadableStatus].
///
/// [LoadableBodyLayout.scrollable] accepts ordinary widgets, fills the available
/// height, and scrolls when content is taller. Use [LoadableBodyLayout.slivers]
/// for lazy lists or other sliver compositions. Do not nest another scroll view
/// inside a scrollable body.
class LoadableScaffold extends StatelessWidget {
  const LoadableScaffold({
    super.key,
    this.statusBuilder,
    this.builder,
    this.appBarBuilder,
    this.bottomNavigationBarBuilder,
    this.floatingButtonBuilder,
    this.persistentFooterButtonsBuilder,
    this.persistentFooterAlignment = .centerEnd,
    this.persistentFooterDecoration,
    this.refreshIndicatorStyle,
    this.onRefresh,
    this.bodyLayout = .fixed,
    this.appBarLayout = .fixed,
    this.extendBodyBehindAppBar = false,
    this.padding = .zero,
    this.backgroundColor,
    this.safeArea = true,
    this.canPop = true,
    this.keyboardDismissBehavior = .manual,
    this.scrollController,
  });

  /// Legacy fallback: false forces Cupertino on every platform.
  /// An explicit [refreshIndicatorStyle] takes precedence.
  static bool useAdaptiveIndicator = true;
  static Widget defaultErrorWidget = const _DefaultError();
  static Widget defaultLoadingWidget = const _DefaultLoading();

  final LoadableStatusBuilder? statusBuilder;
  final LoadableWidgetBuilder? builder;
  final LoadableWidgetBuilder? appBarBuilder;
  final LoadableWidgetBuilder? bottomNavigationBarBuilder;
  final LoadableWidgetBuilder? floatingButtonBuilder;

  final LoadableWidgetListBuilder? persistentFooterButtonsBuilder;
  final AlignmentDirectional persistentFooterAlignment;
  final BoxDecoration? persistentFooterDecoration;

  final RefreshIndicatorStyle? refreshIndicatorStyle;
  final LoadableRefreshCallback? onRefresh;

  final LoadableBodyLayout bodyLayout;
  final LoadableAppBarLayout appBarLayout;
  final bool extendBodyBehindAppBar;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final bool safeArea;
  final bool canPop;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Loadable(
      statusBuilder: statusBuilder,
      builder: (status) => (context) {
        final appBar = appBarBuilder
          ?.build(context, status);

        final bottomNavigationBar = bottomNavigationBarBuilder
          ?.build(context, status);

        final floatingButton = floatingButtonBuilder
          ?.build(context, status);

        final persistentFooterButtons = persistentFooterButtonsBuilder
          ?.build(context, status);

        final page = builder
          ?.build(context, status);

        final body = _page(status, page, appBar);

        final safeBody = safeArea
          ? SafeArea(
              top: appBar == null,
              child: body,
            )
          : body;

        return PopScope(
          canPop: canPop,
          child: Scaffold(
            body: safeBody,
            appBar: appBarLayout == .sliver
              ? null
              : appBar as PreferredSizeWidget?,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingButton,
            backgroundColor: backgroundColor,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            persistentFooterAlignment: persistentFooterAlignment,
            persistentFooterDecoration: persistentFooterDecoration,
            persistentFooterButtons: persistentFooterButtons,
          ),
        );
      },
    );
  }

  Widget _page(
    LoadableStatus status,
    Widget? child,
    Widget? appBar,
  ) {
    child ??= switch (status) {
      .error => defaultErrorWidget,
      .loading => defaultLoadingWidget,
      _ => null,
    };

    final loadedSlivers = status.isLoaded && bodyLayout == .slivers;

    if (status.isLoaded) {
      child = loadedSlivers
        ? SliverPadding(
            padding: padding,
            sliver: child,
          )
        : Padding(
            padding: padding,
            child: child,
          );
    }

    final refreshable = !status.isLoading && onRefresh != null;
    final useCupertinoIndicator = _usesCupertinoRefresh;

    final canScroll = status.isLoaded &&
      (bodyLayout != .fixed || refreshable);

    final physics = canScroll
      ? useCupertinoIndicator
        ? BouncingScrollPhysics(
            parent: refreshable || loadedSlivers
              ? const AlwaysScrollableScrollPhysics()
              : null,
          )
        : refreshable
          ? const AlwaysScrollableScrollPhysics()
          : null
      : const NeverScrollableScrollPhysics();

    return _RefreshableCustomScrollView(
      refreshable: refreshable,
      useCupertinoIndicator: useCupertinoIndicator,
      onRefresh: onRefresh,
      controller: scrollController,
      keyboardDismissBehavior: keyboardDismissBehavior,
      physics: physics,
      appBar: appBarLayout == .sliver ? appBar : null,
      slivers: [
        if (!loadedSlivers) ...[
          SliverFillRemaining(
            hasScrollBody: !status.isLoaded || bodyLayout != .scrollable,
            child: child,
          ),
        ] else if (child != null) ...[
          child,
        ],
      ],
    );
  }

  bool get _usesCupertinoRefresh {
    final style = refreshIndicatorStyle ??
      (useAdaptiveIndicator ? .adaptive : .cupertino);

    return switch (style) {
      .cupertino => true,
      .material => false,
      .adaptive => !kIsWeb && defaultTargetPlatform == .iOS,
    };
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: .only(
        top: 16.0,
      ),
      child: Align(
        alignment: .topCenter,
        child: CupertinoActivityIndicator(
          radius: 14.0,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: .center,
      widthFactor: 0.85,
      child: Column(
        mainAxisAlignment: .center,
        spacing: 12.0,
        children: [
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: .bold,
            ),
          ),
          const Text(
            'We have been notified and will do our best to resolve the problem as soon as possible',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RefreshableCustomScrollView extends StatefulWidget {
  const _RefreshableCustomScrollView({
    this.appBar,
    this.slivers = const [],
    this.physics,
    required this.refreshable,
    required this.useCupertinoIndicator,
    this.onRefresh,
    this.controller,
    this.keyboardDismissBehavior = .manual,
  });

  final bool refreshable;
  final bool useCupertinoIndicator;
  final Widget? appBar;
  final List<Widget> slivers;
  final ScrollPhysics? physics;
  final RefreshCallback? onRefresh;
  final ScrollController? controller;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  State<_RefreshableCustomScrollView> createState() => _RefreshableCustomScrollViewState();
}

class _RefreshableCustomScrollViewState extends State<_RefreshableCustomScrollView> {
  late ScrollController _scrollController;
  var _isScrollAtTop = true;

  @override
  Widget build(BuildContext context) {
    final view = NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        physics: widget.physics,
        slivers: [
          if (widget.appBar != null) ...[
            widget.appBar!,
          ],
          if (widget.refreshable && widget.useCupertinoIndicator && _isScrollAtTop) ...[
            CupertinoSliverRefreshControl(
              onRefresh: widget.onRefresh,
            ),
          ],
          ...widget.slivers,
        ],
      ),
    );

    return widget.refreshable && !widget.useCupertinoIndicator
      ? RefreshIndicator(
          onRefresh: widget.onRefresh!,
          child: view,
        )
      : view;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? .new();
  }

  @override
  void didUpdateWidget(_RefreshableCustomScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _scrollController.dispose();
      }

      _scrollController = widget.controller ?? .new();
      _isScrollAtTop = !_scrollController.hasClients || _scrollController.offset <= 0;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }

    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (_scrollController.offset <= 0 && !_isScrollAtTop) {
        scheduleMicrotask(() {
          if (mounted) {
            setState(() {
              _isScrollAtTop = true;
            });
          }
        });
      } else if (_scrollController.offset > 0 && _isScrollAtTop) {
        scheduleMicrotask(() {
          if (mounted) {
            setState(() {
              _isScrollAtTop = false;
            });
          }
        });
      }
    }

    return false;
  }
}
