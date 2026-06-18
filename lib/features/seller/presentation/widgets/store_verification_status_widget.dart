import 'package:flutter/material.dart';

import '../../domain/entities/store_profile.dart';

class StoreVerificationStatusWidget extends StatelessWidget {
  final StoreProfile storeProfile;
  final VoidCallback? onReapplyPressed;

  const StoreVerificationStatusWidget({
    super.key,
    required this.storeProfile,
    this.onReapplyPressed,
  });

  @override
  Widget build(BuildContext context) {
    late Color backgroundColor;
    late Color borderColor;
    late Color textColor;
    late IconData icon;
    late String title;
    late String description;
    late bool showAction;

    switch (storeProfile.status) {
      case VerificationStatus.verified:
        backgroundColor = Colors.green[50]!;
        borderColor = Colors.green[300]!;
        textColor = Colors.green[700]!;
        icon = Icons.verified;
        title = 'Store Verified';
        description = 'Your store has been verified and is active.';
        showAction = false;

      case VerificationStatus.pending:
      case VerificationStatus.applied:
      case VerificationStatus.underReview:
        backgroundColor = Colors.orange[50]!;
        borderColor = Colors.orange[300]!;
        textColor = Colors.orange[700]!;
        icon = Icons.hourglass_empty;
        title = 'Verification Pending';
        description =
            'Your store is under review. This usually takes 2-3 business days.';
        showAction = false;

      case VerificationStatus.rejected:
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red[300]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        title = 'Verification Rejected';
        description =
            'Your store verification was rejected. Please update your information and reapply.';
        showAction = true;

      case VerificationStatus.suspended:
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red[300]!;
        textColor = Colors.red[700]!;
        icon = Icons.block;
        title = 'Store Suspended';
        description =
            'Your store has been suspended. Please contact support for more information.';
        showAction = false;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: textColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showAction) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReapplyPressed,
                  style: ElevatedButton.styleFrom(backgroundColor: textColor),
                  child: const Text(
                    'Reapply for Verification',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
