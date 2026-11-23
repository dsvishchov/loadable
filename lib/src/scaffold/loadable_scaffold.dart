import 'package:cupertino_ui/cupertino_ui.dart' show
  CupertinoActivityIndicator, CupertinoSliverRefreshControl;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../loadable.dart';

enum LoadableBodyLayout {
  fixed,
  scrollable,
  slivers,
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
    this.persistentFooterAlignment = .centerEnd,
    this.persistentFooterDecoration,
    this.persistentFooterButtonsBuilder,
    this.onRefresh,
    this.padding = .zero,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.bodyLayout = .fixed,
    this.refreshIndicatorStyle,
    this.safeArea = true,
    this.canPop = true,
    this.keyboardDismissBehavior = .manual,
    this.scrollController,
    @Deprecated('Use bodyLayout: LoadableBodyLayout.slivers instead.')
    this.useSlivers = false,
    this.useAppBarAsSliver = false,
  });

  /// Legacy fallback: false forces Cupertino on every platform.
  /// An explicit [refreshIndicatorStyle] takes precedence.
  static bool useAdaptiveIndicator = true;
  static Widget defaultErrorWidget = const _DefaultError();
  static Widget defaultLoadingWidget = const _DefaultLoading();

  final LoadableWidgetBuilder? builder;
  final LoadableStatusBuilder? statusBuilder;
  final LoadableRefreshCallback? onRefresh;
  final LoadableWidgetBuilder? appBarBuilder;
  final LoadableWidgetBuilder? bottomNavigationBarBuilder;
  final LoadableWidgetBuilder? floatingButtonBuilder;
  final AlignmentDirectional persistentFooterAlignment;
  final BoxDecoration? persistentFooterDecoration;
  final LoadableWidgetListBuilder? persistentFooterButtonsBuilder;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final LoadableBodyLayout bodyLayout;
  final RefreshIndicatorStyle? refreshIndicatorStyle;
  final bool safeArea;
  final bool canPop;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final ScrollController? scrollController;
  final bool useSlivers;
  final bool useAppBarAsSliver;

  @override
  Widget build(BuildContext context) {
    return Loadable(
      statusBuilder: statusBuilder,
      builder: (status) => (context) {
        final appBar = appBarBuilder?.build(context, status);

        final body = _page(
          context,
          status,
          builder?.build(context, status),
          appBar,
        );

        return PopScope(
          canPop: canPop,
          child: Scaffold(
            body: safeArea
              ? SafeArea(
                top: appBar == null,
                child: body,
              )
              : body,
            appBar: useAppBarAsSliver ? null : appBar as PreferredSizeWidget?,
            bottomNavigationBar: bottomNavigationBarBuilder?.build(context, status),
            floatingActionButton: floatingButtonBuilder?.build(context, status),
            backgroundColor: backgroundColor,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            persistentFooterAlignment: persistentFooterAlignment,
            persistentFooterDecoration: persistentFooterDecoration,
            persistentFooterButtons: persistentFooterButtonsBuilder?.build(context, status),
          ),
        );
      },
    );
  }

  LoadableBodyLayout get _bodyLayout => useSlivers ? .slivers : bodyLayout;

  Widget _page(
    BuildContext context,
    LoadableStatus status,
    Widget? child,
    Widget? appBar,
  ) {
    child ??= switch (status) {
      .error => defaultErrorWidget,
      .loading => defaultLoadingWidget,
      _ => const SizedBox.shrink(),
    };

    final refreshable = !status.isLoading && onRefresh != null;
    final loadedSlivers = status.isLoaded && _bodyLayout == .slivers;

    final content = status.isLoaded
      ? loadedSlivers
        ? SliverPadding(
          padding: padding,
          sliver: child,
        )
        : Padding(
          padding: padding,
          child: child,
        )
      : child;

    if (_bodyLayout == .fixed && !refreshable && !useAppBarAsSliver) {
      return content;
    }

    final cupertino = _usesCupertinoRefresh;

    final scrollView = CustomScrollView(
      controller: scrollController,
      keyboardDismissBehavior: keyboardDismissBehavior,
      physics: refreshable
        ? cupertino
          ? const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          )
          : const AlwaysScrollableScrollPhysics()
        : _bodyLayout == .fixed
          ? const NeverScrollableScrollPhysics()
          : null,
      slivers: [
        if (useAppBarAsSliver && appBar != null) ...[
          appBar,
        ],
        if (refreshable && cupertino) ...[
          CupertinoSliverRefreshControl(
            onRefresh: onRefresh,
          ),
        ],
        if (loadedSlivers) ...[
          content,
        ] else ...[
          SliverFillRemaining(
            hasScrollBody: !status.isLoaded || _bodyLayout != .scrollable,
            child: content,
          ),
        ],
      ],
    );

    return refreshable && !cupertino
      ? RefreshIndicator(
        onRefresh: onRefresh!,
        child: scrollView,
      )
      : scrollView;
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
    return const Center(
      child: CupertinoActivityIndicator(),
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Something went wrong',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
