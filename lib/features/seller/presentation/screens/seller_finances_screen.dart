import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/features/seller/domain/entities/merchant_wallet.dart';
import 'package:ecom/features/seller/domain/entities/seller_transaction.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_finances_controller.dart';
import 'package:ecom/services/ifsc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SellerFinancesScreen extends ConsumerWidget {
  const SellerFinancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(sellerFinancesControllerProvider);
    final bankAccountAsync = ref.watch(sellerBankAccountProvider);
    final transactionsAsync = ref.watch(sellerTransactionsProvider);

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Finances & Settlements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(sellerFinancesControllerProvider.notifier).refresh();
              ref.invalidate(sellerBankAccountProvider);
              ref.invalidate(sellerTransactionsProvider);
            },
          ),
        ],
      ),
      body: walletAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(sellerFinancesControllerProvider.notifier).refresh(),
        ),
        data: (wallet) {
          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(sellerFinancesControllerProvider.notifier)
                  .refresh();
              ref.invalidate(sellerBankAccountProvider);
              ref.invalidate(sellerTransactionsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Wallet Balance Card
                  _buildBalanceCard(context, ref, wallet, currencyFormat),
                  const SizedBox(height: 20),

                  // Bank Account Section
                  _buildBankAccountSection(context, bankAccountAsync),
                  const SizedBox(height: 20),

                  // Transactions Section
                  _buildTransactionsSection(
                    context,
                    transactionsAsync,
                    currencyFormat,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    WidgetRef ref,
    MerchantWallet wallet,
    NumberFormat currencyFormat,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withRed(100),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(wallet.availableBalance),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (wallet.availableBalance > 0)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _showPayoutDialog(context, ref, wallet),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Withdraw'),
                  ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Locked Escrow Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message:
                                'Funds from purchases are held in escrow for 10 days before they mature into your available balance.',
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.white70.withValues(alpha: 0.6),
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(wallet.lockedBalance),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(wallet.totalBalance),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountSection(
    BuildContext context,
    AsyncValue<Map<String, dynamic>?> bankAccountAsync,
  ) {
    final theme = Theme.of(context);

    return bankAccountAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading bank details: $e'),
      data: (bankAccount) {
        if (bankAccount == null) {
          return Card(
            child: ListTile(
              title: const Text('No Bank Account Configured'),
              subtitle: const Text(
                'Add settlement details to request withdrawals.',
              ),
              trailing: SizedBox(
                width: 130,
                child: ElevatedButton(
                  onPressed: () => _showEditBankDialog(context, null),
                  child: const Text('Configure'),
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settlement Bank Account',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'IFSC Verified',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _showEditBankDialog(context, bankAccount),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBankDetailRow(
                  'Account Holder',
                  bankAccount['holderName'] as String? ?? '',
                ),
                _buildBankDetailRow(
                  'Bank Name',
                  bankAccount['bankName'] as String? ?? '',
                ),
                _buildBankDetailRow(
                  'Account Number',
                  bankAccount['maskedAccountNumber'] as String? ?? '',
                ),
                _buildBankDetailRow(
                  'IFSC Code',
                  bankAccount['ifsc'] as String? ?? '',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(
    BuildContext context,
    AsyncValue<List<SellerTransaction>> transactionsAsync,
    NumberFormat currencyFormat,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Recent Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        transactionsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) =>
              Center(child: Text('Failed to load transactions: $e')),
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transaction history found.'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isCredit = tx.isRevenue;
                final dateStr = DateFormat(
                  'MMM dd, yyyy • hh:mm a',
                ).format(tx.createdAt);

                IconData txIcon;
                Color txColor;
                switch (tx.type) {
                  case TransactionType.orderRevenue:
                    txIcon = Icons.arrow_downward;
                    txColor = Colors.green;
                    break;
                  case TransactionType.payoutRequest:
                  case TransactionType.payoutCompleted:
                    txIcon = Icons.arrow_upward;
                    txColor = Colors.blue;
                    break;
                  case TransactionType.refund:
                    txIcon = Icons.history;
                    txColor = Colors.orange;
                    break;
                  case TransactionType.platformFee:
                    txIcon = Icons.money_off;
                    txColor = Colors.redAccent;
                    break;
                  default:
                    txIcon = Icons.payment;
                    txColor = Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: txColor.withValues(alpha: 0.1),
                      child: Icon(txIcon, color: txColor),
                    ),
                    title: Text(
                      tx.description ?? _getTransactionTypeName(tx.type),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      dateStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isCredit ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              tx.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.status.value.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(tx.status),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _getTransactionTypeName(TransactionType type) {
    switch (type) {
      case TransactionType.orderRevenue:
        return 'Order Revenue';
      case TransactionType.payoutRequest:
        return 'Payout Request';
      case TransactionType.payoutCompleted:
        return 'Payout Completed';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.platformFee:
        return 'Platform Fee';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }

  void _showPayoutDialog(
    BuildContext context,
    WidgetRef ref,
    MerchantWallet wallet,
  ) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Payout'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Maximum available to withdraw: ₹${wallet.availableBalance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 500',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an amount';
                    }
                    final amt = double.tryParse(value);
                    if (amt == null || amt <= 0) {
                      return 'Enter a valid positive amount';
                    }
                    if (amt > wallet.availableBalance) {
                      return 'Amount exceeds available balance';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final amt = double.parse(amountController.text.trim());
                  ref
                      .read(sellerFinancesControllerProvider.notifier)
                      .requestPayout(
                        amount: amt,
                        bankAccountId: wallet.storeId,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }

  void _showEditBankDialog(
    BuildContext context,
    Map<String, dynamic>? currentBank,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _BankAccountDialog(currentBank: currentBank),
    );
  }
}

class _BankAccountDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? currentBank;

  const _BankAccountDialog({this.currentBank});

  @override
  ConsumerState<_BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends ConsumerState<_BankAccountDialog> {
  static final RegExp _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final RegExp _namePattern = RegExp(r"^[a-zA-Z\s.'-]+$");
  static const int _ifscLength = 11;
  static const int _minAccountNumberLength = 9;
  static const int _maxAccountNumberLength = 18;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _holderController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _confirmAccountNumberController;
  late final TextEditingController _ifscController;

  IfscBankDetails? _verifiedDetails;
  String? _ifscError;
  bool _isFetchingIfsc = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final bank = widget.currentBank;
    final existingAccountNumber = bank?['accountNumber'] as String? ?? '';
    final existingIfsc = (bank?['ifsc'] as String? ?? '').toUpperCase();

    _holderController = TextEditingController(
      text: bank?['holderName'] as String? ?? '',
    );
    _accountNumberController = TextEditingController(
      text: existingAccountNumber,
    );
    _confirmAccountNumberController = TextEditingController(
      text: existingAccountNumber,
    );
    _ifscController = TextEditingController(text: existingIfsc);

    if (existingIfsc.length == _ifscLength &&
        _ifscPattern.hasMatch(existingIfsc)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyIfsc(existingIfsc);
      });
    }
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _verifyIfsc(String code) async {
    if (!mounted) return;
    setState(() {
      _isFetchingIfsc = true;
      _ifscError = null;
      _verifiedDetails = null;
    });

    try {
      final details = await IfscService.fetchByIfsc(code);
      if (!mounted) return;
      setState(() {
        _verifiedDetails = details;
        _isFetchingIfsc = false;
      });
    } on IfscNotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _ifscError = e.toString();
        _isFetchingIfsc = false;
      });
    } on IfscFetchException catch (e) {
      if (!mounted) return;
      setState(() {
        _ifscError = e.toString();
        _isFetchingIfsc = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ifscError = 'Could not verify IFSC code. Please try again.';
        _isFetchingIfsc = false;
      });
    }
  }

  void _onIfscChanged(String rawValue) {
    final upper = rawValue.toUpperCase();
    if (upper != rawValue) {
      _ifscController.value = TextEditingValue(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }

    setState(() {
      _verifiedDetails = null;
      _ifscError = null;
    });

    if (upper.length == _ifscLength) {
      if (_ifscPattern.hasMatch(upper)) {
        _verifyIfsc(upper);
      } else {
        setState(() => _ifscError = 'Invalid IFSC code format.');
      }
    }
  }

  String? _validateIfsc(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return 'IFSC code is required';
    if (v.length != _ifscLength) return 'IFSC code must be 11 characters';
    if (!_ifscPattern.hasMatch(v)) return 'Invalid IFSC code format';
    if (_isFetchingIfsc) return 'Verifying IFSC code…';
    if (_verifiedDetails == null) return 'Please verify the IFSC code';
    return null;
  }

  String? _validateHolderName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Account holder name is required';
    if (v.length < 3) return 'Enter a valid name';
    if (!_namePattern.hasMatch(v)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Account number is required';
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Digits only';
    if (v.length < _minAccountNumberLength) {
      return 'Account number is too short';
    }
    if (v.length > _maxAccountNumberLength) {
      return 'Account number is too long';
    }
    return null;
  }

  String? _validateConfirmAccountNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please confirm the account number';
    if (v != _accountNumberController.text.trim()) {
      return 'Account numbers do not match';
    }
    return null;
  }

  bool get _isFormValid {
    return _validateHolderName(_holderController.text) == null &&
        _validateAccountNumber(_accountNumberController.text) == null &&
        _validateConfirmAccountNumber(_confirmAccountNumberController.text) ==
            null &&
        _ifscPattern.hasMatch(_ifscController.text.trim().toUpperCase());
  }

  bool get _canSave =>
      _verifiedDetails != null &&
      _isFormValid &&
      !_isSaving &&
      !_isFetchingIfsc;

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final details = _verifiedDetails;
    if (details == null) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(sellerFinancesControllerProvider.notifier)
          .updateBankAccount(
            ifsc: _ifscController.text.trim().toUpperCase(),
            accountNumber: _accountNumberController.text.trim(),
            holderName: _holderController.text.trim(),
            bankName: details.bankName,
            branch: details.branch,
            city: details.city,
            bankState: details.state,
            address: details.address,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save bank details: $e')),
      );
      return;
    }

    if (!mounted) return;

    final resultState = ref.read(sellerFinancesControllerProvider);
    if (resultState.hasError) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save bank details: ${resultState.error}'),
        ),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  Widget? _buildIfscSuffixIcon() {
    if (_isFetchingIfsc) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_verifiedDetails != null) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (_ifscError != null) {
      return const Icon(Icons.error, color: Colors.red);
    }
    return null;
  }

  Widget _buildVerifiedBankCard(IfscBankDetails details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Bank Verified',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _verifiedRow('Bank', details.bankName),
          _verifiedRow('Branch', details.branch),
          _verifiedRow('City', details.city),
          _verifiedRow('State', details.state),
        ],
      ),
    );
  }

  Widget _verifiedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.currentBank == null
            ? 'Configure Bank Details'
            : 'Edit Bank Details',
      ),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                maxLength: _ifscLength,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: 'IFSC Code',
                  counterText: '',
                  suffixIcon: _buildIfscSuffixIcon(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(_ifscLength),
                ],
                onChanged: (value) {
                  _onIfscChanged(value);
                  setState(() {});
                },
                validator: _validateIfsc,
              ),
              if (_ifscError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _ifscError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              if (_verifiedDetails != null) ...[
                const SizedBox(height: 12),
                _buildVerifiedBankCard(_verifiedDetails!),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _holderController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                ),
                validator: _validateHolderName,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Account Number'),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxAccountNumberLength),
                ],
                validator: _validateAccountNumber,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmAccountNumberController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Confirm Account Number',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxAccountNumberLength),
                ],
                validator: _validateConfirmAccountNumber,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave ? _handleSave : null,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
