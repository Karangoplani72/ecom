import 'dart:async';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/marketplace/data/repositories/logistics_repository_impl.dart';
import 'package:ecom/features/marketplace/domain/entities/delivery_assignment.dart';
import 'package:ecom/features/marketplace/domain/repositories/logistics_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logistics_controller.g.dart';

@riverpod
LogisticsRepository logisticsRepository(Ref ref) {
  return LogisticsRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Stream<DeliveryAssignment> realTimeDispatchStream(Ref ref, String orderId) {
  return ref.watch(logisticsRepositoryProvider).streamActiveAssignment(orderId);
}

@riverpod
class LogisticsController extends _$LogisticsController {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> submitLiveCoordinates(
    String assignmentId,
    double lat,
    double lng,
  ) async {
    final repo = ref.read(logisticsRepositoryProvider);

    await repo.updateAgentCoordinates(assignmentId, lat, lng);
  }

  Future<bool> transitionWorkflowStage(
    String assignmentId,
    AssignmentStatus stage, {
    String? verificationCode,
  }) async {
    state = const AsyncValue.loading();

    final repo = ref.read(logisticsRepositoryProvider);

    final result = await repo.advanceAssignmentStatus(
      assignmentId,
      stage,
      inputOtp: verificationCode,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}
