import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ecom/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:ecom/features/admin/domain/entities/dispute_ticket.dart';
import 'package:ecom/features/admin/domain/repositories/admin_repository.dart';

part 'admin_controller.g.dart';

@riverpod
AdminRepository adminRepository(
    Ref ref,
    ) {
  return AdminRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
}

@riverpod
class AdminController extends _$AdminController {
  @override
  FutureOr<List<DisputeTicket>> build() async {
    final repo = ref.read(
      adminRepositoryProvider,
    );

    final result = await repo.fetchActiveDisputes(
      limit: 50,
    );

    return result.fold(
          (error) => throw Exception(error),
          (tickets) => tickets,
    );
  }

  Future<void> adjustTicketWorkflow(
      String id,
      TicketStatus status,
      ) async {
    state = const AsyncValue.loading();

    final repo = ref.read(
      adminRepositoryProvider,
    );

    final result = await repo.updateTicketStatus(
      id,
      status,
    );

    result.fold(
          (failure) {
        state = AsyncValue.error(
          failure,
          StackTrace.current,
        );
      },
          (_) async {
        final freshTickets =
        await repo.fetchActiveDisputes(
          limit: 50,
        );

        state = freshTickets.fold(
              (error) => AsyncValue.error(
            error,
            StackTrace.current,
          ),
              (tickets) => AsyncValue.data(
            tickets,
          ),
        );
      },
    );
  }
}