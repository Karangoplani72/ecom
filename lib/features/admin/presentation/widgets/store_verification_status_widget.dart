import 'package:ecom/features/seller/domain/entities/store_profile.dart';
import 'package:flutter/material.dart';

class StoreVerificationStatusWidget extends StatelessWidget {
  final StoreProfile? storeProfile;
  final VoidCallback? onSubmitForReview;
  final VoidCallback? onEditProfile;

  const StoreVerificationStatusWidget({
    super.key,
    required this.storeProfile,
    this.onSubmitForReview,
    this.onEditProfile,
  });

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.applied:
      case VerificationStatus.underReview:
        return const Color(0xFFF59E0B); // Amber
      case VerificationStatus.verified:
        return const Color(0xFF16A34A); // Green
      case VerificationStatus.rejected:
        return const Color(0xFFDC2626); // Red
      case VerificationStatus.suspended:
        return const Color(0xFF7C3AED); // Violet
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.applied:
        return Icons.schedule_rounded;
      case VerificationStatus.underReview:
        return Icons.visibility_rounded;
      case VerificationStatus.verified:
        return Icons.verified_user_rounded;
      case VerificationStatus.rejected:
        return Icons.cancel_rounded;
      case VerificationStatus.suspended:
        return Icons.block_rounded;
    }
  }

  String _getStatusLabel(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.applied:
        return 'Applied';
      case VerificationStatus.underReview:
        return 'Under Review';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.suspended:
        return 'Suspended';
    }
  }

  String _getStatusMessage(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.applied:
        return 'Your store application has been submitted. Admin review is pending.';
      case VerificationStatus.underReview:
        return 'Your store is under admin review. We will notify you soon.';
      case VerificationStatus.verified:
        return 'Your store has been verified! You can now publish products.';
      case VerificationStatus.rejected:
        return 'Your store application was rejected. Please review feedback and reapply.';
      case VerificationStatus.suspended:
        return 'Your store has been suspended. Please contact support for details.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (storeProfile == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Store Verification Required',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to create and submit your store profile before you can publish products.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSubmitForReview,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Store Profile'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final status = storeProfile!.status;
    final isVerified = status == VerificationStatus.verified;
    final canBeEdited =
        status == VerificationStatus.applied ||
        status == VerificationStatus.rejected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Status',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _getStatusLabel(status),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(status).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _getStatusMessage(status),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (!isVerified) ...[
              const SizedBox(height: 12),
              Text(
                'You cannot publish products until your store is verified.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFDC2626),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (canBeEdited) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Profile'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
