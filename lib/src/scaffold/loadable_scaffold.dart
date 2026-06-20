import 'dart:async';

import 'package:flutter/cupertino.dart' show
  CupertinoActivityIndicator, CupertinoSliverRefreshControl;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../loadable.dart';

/// [LoadableScaffold] provides a convenient way to handle multiple statuses
/// and build scaffold body as well as other essential elements like `appBar`,
/// `bottomNavigationBar` or `floatingButton` based on [LoadableStatus].
///
/// Optional `onRefresh` callback, if provided, enables pull to refresh
/// functionality and will be called upon action taken by the user.
///
/// Widget returned by `builder` might be any descendant of [Widget] unless
/// `useSlivers` option specified. In this case for [LoadableStats.loaded]
/// a sliver should be returned instead.
///
/// If slivers are used then scrolling functionality is available
/// out of the box, if not, but scrolling functionality is still required,
/// then any other scrollable widget must be used,  e.g. [ListView],
/// however in this case pull to refresh functionality must be handled manually.

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
    this.useSlivers = false,
    this.useAppBarAsSliver = false,
  });

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
  final bool useSlivers;
  final bool useAppBarAsSliver;

  @override
  Widget build(BuildContext context) {
    return Loadable(
      key: key,
      statusBuilder: statusBuilder,
      builder: (status) => (context) {
        final appBar = appBarBuilder
          ?.build(context, status) as PreferredSizeWidget?;

        final bottomNavigationBar = bottomNavigationBarBuilder
          ?.build(context, status);

        final floatingButton = floatingButtonBuilder
          ?.build(context, status);

        final persistentFooterButtons = persistentFooterButtonsBuilder
          ?.build(context, status);

        final page = builder
          ?.build(context, status);

        return Scaffold(
          body: _page(context, status, page, appBar),
          appBar: !useAppBarAsSliver ? appBar : null,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingButton,
          backgroundColor: backgroundColor,
          persistentFooterAlignment: persistentFooterAlignment,
          persistentFooterDecoration: persistentFooterDecoration,
          persistentFooterButtons: persistentFooterButtons,
        );
      },
    );
  }

  Widget? _page(
    BuildContext context,
    LoadableStatus status,
    Widget? child,
    PreferredSizeWidget? appBar,
  ) {
    child ??= switch (status) {
      .error => defaultErrorWidget,
      .loading => defaultLoadingWidget,
      _ => null,
    };

    if (status.isLoaded) {
      final safeBottom = EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom
      );

      child = useSlivers
        ? SliverPadding(
            padding: padding + safeBottom,
            sliver: child,
          )
        : Padding(
            padding: padding,
            child: child,
          );
    }

    final refreshable = !status.isLoading && (onRefresh != null);
    final useCupertinoIndicator = (!kIsWeb && (defaultTargetPlatform == .iOS)) || !useAdaptiveIndicator;

    final view = _RefreshableCustomScrollView(
      refreshable: refreshable,
      useCupertinoIndicator: useCupertinoIndicator,
      onRefresh: () => onRefresh!(),
      physics: BouncingScrollPhysics(
        parent: status.isLoaded && (useSlivers || (refreshable && useCupertinoIndicator))
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      ),
      appBar: useAppBarAsSliver ? appBar : null,
      slivers: [
        if (!status.isLoaded || !useSlivers) ...[
          SliverFillRemaining(child: child),
        ] else if (child != null) ...[
          child,
        ],
      ],
    );

    return view;
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: .only(top: 16.0),
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
      child:  Column(
        mainAxisAlignment: .center,
        spacing: 12.0,
        children: [
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'We have been notified and will do our best to resolve the problem as soon as possible',
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}

class _RefreshableCustomScrollView extends StatefulWidget {
  const _RefreshableCustomScrollView({
    this.appBar,
    this.slivers = const <Widget>[],
    this.physics,
    required this.refreshable,
    required this.useCupertinoIndicator,
    this.onRefresh,
  });

  final bool refreshable;
  final bool useCupertinoIndicator;
  final Widget? appBar;
  final List<Widget> slivers;
  final ScrollPhysics? physics;
  final RefreshCallback? onRefresh;

  @override
  State<_RefreshableCustomScrollView> createState() => _RefreshableCustomScrollViewState();
}

class _RefreshableCustomScrollViewState extends State<_RefreshableCustomScrollView> {
  final _scrollController = ScrollController();
  var _isScrollAtTop = true;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
        controller: _scrollController,
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
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (_scrollController.offset <= 0 && !_isScrollAtTop) {
        scheduleMicrotask(() {
          if (mounted) {
            setState(() => _isScrollAtTop = true);
          }
        });
      } else if (_scrollController.offset > 0 && _isScrollAtTop) {
        scheduleMicrotask(() {
          if (mounted) {
            setState(() => _isScrollAtTop = false);
          }
        });
      }
    }
    return false;
  }
}