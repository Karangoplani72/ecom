import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@riverpod
Stream<bool> isConnected(Ref ref) async* {
  final connectivity = Connectivity();

  // Initial check
  final initialList = await connectivity.checkConnectivity();
  yield _hasConnection(initialList);

  // Stream listening
  await for (final result in connectivity.onConnectivityChanged) {
    yield _hasConnection(result);
  }
}

bool _hasConnection(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  if (results.length == 1 && results.first == ConnectivityResult.none) {
    return false;
  }
  return true;
}
