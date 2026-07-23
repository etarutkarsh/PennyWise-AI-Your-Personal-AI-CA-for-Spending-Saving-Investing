import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_entity.dart';
import 'add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // TODO: replace with TransactionsBloc backed by GET /transactions.
  final List<TransactionEntity> _transactions = [];

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: _transactions.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final isDebit = tx.direction == 'DEBIT';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isDebit ? AppColors.danger : AppColors.success,
                        size: 18,
                      ),
                    ),
                    title: Text(tx.merchant),
                    subtitle: Text('${tx.categoryName} • ${DateFormat.MMMd().format(tx.transactionDate)}'),
                    trailing: Text(
                      '${isDebit ? '-' : '+'}${currency.format(tx.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDebit ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddTransactionSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add manually'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'No transactions yet',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Grant SMS/notification access so PennyWise can auto-detect spending, '
              'or add one manually below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
