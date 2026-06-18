import 'package:flutter/material.dart';

import '../../domain/entities/store_profile.dart';

class SellerStoreHeader extends StatelessWidget {
  final StoreProfile storeProfile;
  final VoidCallback? onEditPressed;

  const SellerStoreHeader({
    super.key,
    required this.storeProfile,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Banner
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.blue[100],
                ),
                child: storeProfile.bannerUrl != null
                    ? Image.network(
                        storeProfile.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                      )
                    : Center(
                        child: Icon(
                          Icons.store,
                          size: 60,
                          color: Colors.blue[300],
                        ),
                      ),
              ),
              if (onEditPressed != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    onPressed: onEditPressed,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.edit),
                  ),
                ),
            ],
          ),
          // Store Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and Name
                Row(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: storeProfile.logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                storeProfile.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.store),
                              ),
                            )
                          : const Icon(Icons.store),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeProfile.storeName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _VerificationBadge(status: storeProfile.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Store Details
                Text(
                  storeProfile.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Contact Info
                if (storeProfile.phone != null &&
                    storeProfile.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          storeProfile.phone!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                if (storeProfile.email != null &&
                    storeProfile.email!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.email, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          storeProfile.email!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final VerificationStatus status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color backgroundColor;
    late Color textColor;
    late String label;

    switch (status) {
      case VerificationStatus.verified:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        label = 'Verified';
      case VerificationStatus.pending:
      case VerificationStatus.applied:
      case VerificationStatus.underReview:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        label = 'Pending Review';
      case VerificationStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        label = 'Rejected';
      case VerificationStatus.suspended:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        label = 'Suspended';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
