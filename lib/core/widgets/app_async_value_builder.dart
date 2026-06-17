import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_error_view.dart';
import 'app_loading_view.dart';

class AppAsyncValueBuilder<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  const AppAsyncValueBuilder({
    super.key,
    required this.value,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => builder(data),
      loading: () => const AppLoadingView(),
      error: (error, stack) => AppErrorView(message: error.toString()),
    );
  }
}
