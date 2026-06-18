import 'package:flutter/material.dart';

class SellerSidebarItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final String? badge;

  SellerSidebarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.badge,
  });
}

class SellerSidebar extends StatelessWidget {
  final List<SellerSidebarItem> items;
  final String sellerName;
  final String? sellerAvatarUrl;
  final VoidCallback? onLogoutPressed;

  const SellerSidebar({
    super.key,
    required this.items,
    required this.sellerName,
    this.sellerAvatarUrl,
    this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[700]!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: sellerAvatarUrl != null
                      ? NetworkImage(sellerAvatarUrl!)
                      : null,
                  child: sellerAvatarUrl == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  sellerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: List.generate(items.length, (index) {
                final item = items[index];
                return ListTile(
                  leading: Stack(
                    children: [
                      Icon(item.icon),
                      if (item.badge != null)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(item.label),
                  tileColor: item.isActive
                      ? Colors.blue[100]
                      : Colors.transparent,
                  selected: item.isActive,
                  onTap: item.onTap,
                );
              }),
            ),
          ),
          // Logout
          if (onLogoutPressed != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: onLogoutPressed,
              ),
            ),
        ],
      ),
    );
  }
}
