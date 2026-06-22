import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/auth/domain/entities/user_address.dart';
import 'package:ecom/features/auth/presentation/controllers/address_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  void _showAddressForm(
    BuildContext context,
    WidgetRef ref, {
    UserAddress? address,
  }) {
    final fullNameController = TextEditingController(text: address?.fullName);
    final phoneController = TextEditingController(text: address?.phone);
    final address1Controller = TextEditingController(
      text: address?.addressLine1,
    );
    final address2Controller = TextEditingController(
      text: address?.addressLine2,
    );
    final cityController = TextEditingController(text: address?.city);
    final stateController = TextEditingController(text: address?.state);
    final pincodeController = TextEditingController(text: address?.pincode);
    bool isDefault = address?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  address == null ? 'Add New Address' : 'Edit Address',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: address1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: address2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: pincodeController,
                        decoration: const InputDecoration(labelText: 'Pincode'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Set as default address'),
                  value: isDefault,
                  onChanged: (val) => setModalState(() => isDefault = val),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    final newAddress = UserAddress(
                      id: address?.id ?? '',
                      fullName: fullNameController.text,
                      phone: phoneController.text,
                      addressLine1: address1Controller.text,
                      addressLine2: address2Controller.text,
                      city: cityController.text,
                      state: stateController.text,
                      country: 'India',
                      pincode: pincodeController.text,
                      isDefault: isDefault,
                    );

                    if (address == null) {
                      ref
                          .read(addressControllerProvider.notifier)
                          .addAddress(newAddress);
                    } else {
                      ref
                          .read(addressControllerProvider.notifier)
                          .updateAddress(newAddress);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save Address'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(userAddressesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses'), centerTitle: true),
      body: ResponsiveLayout(
        maxWidth: 800,
        child: addressesAsync.when(
          loading: () => const AppLoadingView(),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (addresses) {
            if (addresses.isEmpty) {
              return AppEmptyView(
                title: 'No saved addresses',
                subtitle: 'Add an address to start shopping!',
                icon: Icons.location_off_outlined,
                action: FilledButton.icon(
                  onPressed: () => _showAddressForm(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Address'),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: colorScheme.surface,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: address.isDefault
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: address.isDefault ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Text(
                              address.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(address.fullAddress),
                            Text('Phone: ${address.phone}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                            if (!address.isDefault) ...[
                              const PopupMenuItem(
                                value: 'default',
                                child: Text('Set as Default'),
                              ),
                            ],
                          ],
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showAddressForm(context, ref, address: address);
                            } else if (val == 'delete') {
                              ref
                                  .read(addressControllerProvider.notifier)
                                  .deleteAddress(address.id);
                            } else if (val == 'default') {
                              ref
                                  .read(addressControllerProvider.notifier)
                                  .setDefault(address.id);
                            }
                          },
                        ),
                      ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressForm(context, ref),
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }
}
