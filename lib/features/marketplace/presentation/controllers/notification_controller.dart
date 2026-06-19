import 'dart:async';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/marketplace/domain/entities/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_controller.g.dart';

@riverpod
Stream<List<AppNotification>> userNotifications(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return ref
      .watch(firebaseFirestoreProvider)
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
            .toList(),
      );
}

@riverpod
class NotificationController extends _$NotificationController {
  @override
  FutureOr<void> build() {}

  Future<void> markAsRead(String notificationId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final firestore = ref.read(firebaseFirestoreProvider);
    final batch = firestore.batch();
    final query = await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
