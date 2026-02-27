import 'package:activity_bloc/activity_bloc.dart';
import 'package:flutter/material.dart';

/// [Loadable] provides a convenient way to handle multiple widget
/// statuses based on status of an asynchronous operation.
///
/// There are five different statuses, provided by [LoadableStatus].
/// Content is shown based on `builder` which should return an appropriate
/// widget builder based on the current [LoadableStatus].
///
/// Current status should be provided within `statusBuilder`.
class Loadable extends StatelessWidget {
  const Loadable({
    super.key,
    required this.builder,
    this.statusBuilder,
  });

  final LoadableWidgetBuilder builder;
  final LoadableStatusBuilder? statusBuilder;

  @override
  Widget build(BuildContext context) {
    final status = statusBuilder?.call() ?? .loaded;
    final child = builder.build(context, status);

    return child ?? const SizedBox();
  }
}

/// Widget builder type based on current status
typedef LoadableWidgetBuilder = WidgetBuilder? Function(LoadableStatus);

typedef ListBuilder<T> = List<T> Function(BuildContext);

/// Widgets list builder type based on current status
typedef LoadableWidgetListBuilder = ListBuilder<Widget>? Function(LoadableStatus);

extension LoadableWidgetBuilderBuild on LoadableWidgetBuilder {
  Widget? build(
    BuildContext context,
    LoadableStatus status,
  ) => this(status)?.call(context);
}

extension LoadableWidgetListBuilderBuild on LoadableWidgetListBuilder {
  List<Widget>? build(
    BuildContext context,
    LoadableStatus status,
  ) => this(status)?.call(context);
}

/// Status builder type
typedef LoadableStatusBuilder = LoadableStatus? Function();

/// Pull to refresh callback type
typedef LoadableRefreshCallback = Future<void> Function();

/// Status of [Loadable] widget which direcly reflects which
/// builder is used to render widget based on its status
enum LoadableStatus {
  none,
  loading,
  loaded,
  error;

  bool get isNone => this == .none;
  bool get isLoading => this == .loading;
  bool get isLoaded => this == .loaded;
  bool get isError => this == .error;
}

/// Extension to simplify selecting required widget builder based on
/// the status and allow to skip `null` within exhaustiveness check
extension LoadableWidgetBuilderByStatusWhen on LoadableStatus {
  WidgetBuilder? when({
    WidgetBuilder? none,
    WidgetBuilder? loading,
    WidgetBuilder? loaded,
    WidgetBuilder? error,
  }) {
    return switch (this) {
      .none => none,
      .loading => loading,
      .loaded => loaded,
      .error => error,
    };
  }
}

/// Extension to convert [ActivityBloc] status reflected by
/// [ActivityBloc.status] into [LoadableStatus].
///
/// This might be convenient when [ActivityBloc] is used
/// as a main source of [Loadable] state and data
extension ActivityBlocToLoadableStatus on ActivityBloc {
  LoadableStatus get asLoadableStatus {
    return switch (state.status) {
      .running => .loading,
      .completed => .loaded,
      .failed => .error,
      _ => .none
    };
  }
}