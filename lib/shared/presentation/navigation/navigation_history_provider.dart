import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maintains a history stack of visited routes across all modules.
/// This allows the system back button to retrace steps across tabs
/// and modules, providing a unified navigation experience.
class NavigationHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return [];
  }

  /// Pushes a new route onto the history stack.
  /// Ignores duplicate consecutive routes.
  void pushRoute(String route) {
    if (state.isEmpty || state.last != route) {
      state = [...state, route];
    }
  }

  /// Pops the current route and returns the previous route in the stack.
  /// Returns null if there is no previous route to pop to.
  String? popRoute() {
    if (state.length > 1) {
      final newState = List<String>.from(state)..removeLast();
      state = newState;
      return newState.last;
    }
    return null;
  }

  /// Clears the history stack.
  void clear() {
    state = [];
  }
}

final navigationHistoryProvider =
    NotifierProvider<NavigationHistoryNotifier, List<String>>(
  NavigationHistoryNotifier.new,
);
