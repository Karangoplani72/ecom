import 'package:ecom/core/providers/common_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_name_resolver.g.dart';

@riverpod
class AdminNameResolver extends _$AdminNameResolver {
  final Map<String, String> _userCache = {};
  final Map<String, String> _storeCache = {};

  @override
  void build() {}

  Future<String> resolveUserName(String uid) async {
    if (uid.isEmpty) return 'System / Guest';
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }
    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final email = data?['email'] as String? ?? 'No Email';
        final displayName = data?['displayName'] as String? ?? '';
        final resolvedName = displayName.isNotEmpty ? '$displayName ($email)' : email;
        _userCache[uid] = resolvedName;
        return resolvedName;
      }
    } catch (_) {}
    return uid.length > 8 ? uid.substring(0, 8).toUpperCase() : uid;
  }

  Future<String> resolveStoreName(String storeId) async {
    if (storeId.isEmpty) return 'Unknown Store';
    if (_storeCache.containsKey(storeId)) {
      return _storeCache[storeId]!;
    }
    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      final doc = await firestore.collection('stores').doc(storeId).get();
      if (doc.exists) {
        final data = doc.data();
        final storeName = data?['storeName'] as String? ?? 'Unknown Store';
        _storeCache[storeId] = storeName;
        return storeName;
      }
    } catch (_) {}
    return storeId.length > 8 ? storeId.substring(0, 8).toUpperCase() : storeId;
  }
}
