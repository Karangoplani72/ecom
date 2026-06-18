import 'package:flutter/material.dart';

import '../../domain/entities/seller_product.dart';

class SellerInventoryTable extends StatelessWidget {
  final List<SellerProduct> products;
  final VoidCallback Function(String productId)? onEditPressed;
  final VoidCallback Function(String productId)? onDeletePressed;

  const SellerInventoryTable({
    super.key,
    required this.products,
    this.onEditPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No products found',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Price'), numeric: true),
            DataColumn(label: Text('Stock'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: List.generate(products.length, (index) {
            final product = products[index];
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(product.category)),
                DataCell(Text('₹${product.basePrice.toStringAsFixed(2)}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.isOutOfStock
                          ? Colors.red[100]
                          : product.isLowStock
                          ? Colors.orange[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.stock.toString(),
                      style: TextStyle(
                        color: product.isOutOfStock
                            ? Colors.red[700]
                            : product.isLowStock
                            ? Colors.orange[700]
                            : Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? Colors.green[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.status,
                      style: TextStyle(
                        color: product.isActive
                            ? Colors.green[700]
                            : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (onEditPressed != null)
                        PopupMenuItem(
                          onTap: () => onEditPressed?.call(product.id),
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDeletePressed != null)
                        PopupMenuItem(
                          onTap: () => onDeletePressed?.call(product.id),
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
                    child: const Icon(Icons.more_vert, size: 16),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
