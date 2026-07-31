import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/document_model.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  List<DocumentModel> _docs = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedType;

  static const _filters = [
    (label: 'All', value: null),
    (label: 'Form 16', value: 'FORM_16'),
    (label: 'Form 26AS', value: 'FORM_26AS'),
    (label: 'AIS', value: 'AIS'),
    (label: 'Receipts', value: 'RECEIPT'),
    (label: 'Salary Slip', value: 'SALARY_SLIP'),
    (label: 'Insurance', value: 'INSURANCE'),
    (label: 'Home Loan', value: 'HOME_LOAN'),
    (label: 'Mutual Fund', value: 'MUTUAL_FUND'),
    (label: 'Previous ITR', value: 'PREVIOUS_ITR'),
    (label: 'Other', value: 'OTHER'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docs = await AppServices.instance.documents.getAll(type: _selectedType);
      if (mounted) setState(() => _docs = docs);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          doc.originalFilename ?? _formatDocType(doc.documentType),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await AppServices.instance.documents.delete(doc.id);
      setState(() => _docs.removeWhere((d) => d.id == doc.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _verify(DocumentModel doc) async {
    try {
      final updated = await AppServices.instance.documents.verify(doc.id);
      setState(() {
        final idx = _docs.indexWhere((d) => d.id == doc.id);
        if (idx != -1) _docs[idx] = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document verified')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _addDocument() async {
    const docTypes = [
      ('Form 16', 'FORM_16'),
      ('Form 26AS', 'FORM_26AS'),
      ('AIS', 'AIS'),
      ('Receipt', 'RECEIPT'),
      ('Salary Slip', 'SALARY_SLIP'),
      ('Insurance', 'INSURANCE'),
      ('Home Loan', 'HOME_LOAN'),
      ('Mutual Fund', 'MUTUAL_FUND'),
      ('Previous ITR', 'PREVIOUS_ITR'),
      ('Other', 'OTHER'),
    ];

    final selectedType = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Document type'),
        children: docTypes
            .map((t) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, t.$2),
                  child: Text(t.$1),
                ))
            .toList(),
      ),
    );
    if (selectedType == null || !mounted) return;

    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final fyCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${_formatDocType(selectedType)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'File name',
                hintText: 'e.g. form16_2024.pdf',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'File URL (optional)',
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: fyCtrl,
              decoration: const InputDecoration(
                labelText: 'Financial year (optional)',
                hintText: 'e.g. 2025-26',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final doc = await AppServices.instance.documents.create(
        documentType: selectedType,
        originalFilename: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        fileUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
        financialYear: fyCtrl.text.trim().isEmpty ? null : fyCtrl.text.trim(),
      );
      setState(() => _docs.insert(0, doc));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Document added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _formatDocType(String raw) => raw
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  IconData _iconFor(String docType) => switch (docType) {
        'FORM_16' => Icons.description_rounded,
        'FORM_26AS' => Icons.receipt_long_rounded,
        'AIS' => Icons.account_balance_rounded,
        'RECEIPT' => Icons.receipt_rounded,
        'SALARY_SLIP' => Icons.payments_rounded,
        'INSURANCE' => Icons.health_and_safety_rounded,
        'HOME_LOAN' => Icons.home_rounded,
        'MUTUAL_FUND' => Icons.trending_up_rounded,
        'PREVIOUS_ITR' => Icons.history_edu_rounded,
        _ => Icons.folder_rounded,
      };

  Color _colorFor(String docType) => switch (docType) {
        'FORM_16' || 'FORM_26AS' || 'AIS' || 'PREVIOUS_ITR' => AppColors.primary,
        'RECEIPT' || 'SALARY_SLIP' => AppColors.accent,
        'INSURANCE' || 'HOME_LOAN' || 'MUTUAL_FUND' => AppColors.secondary,
        _ => AppColors.textSecondary,
      };

  Widget _verificationBadge(String status) {
    final (label, color) = switch (status) {
      'VERIFIED' => ('Verified', AppColors.success),
      'DISPUTED' => ('Disputed', AppColors.danger),
      _ => ('Unverified', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _ocrBadge(String status) {
    final (label, color) = switch (status) {
      'COMPLETED' => ('OCR done', AppColors.success),
      'PROCESSING' => ('Processing', AppColors.warning),
      'FAILED' => ('OCR failed', AppColors.danger),
      _ => ('Pending OCR', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Document'),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = _selectedType == f.value;
                return FilterChip(
                  label: Text(f.label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedType = f.value);
                    _load();
                  },
                );
              },
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _docs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_open_rounded,
                                    size: 64,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No documents yet',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap + to add Form 16, receipts, and more',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: _docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final doc = _docs[i];
                              return Dismissible(
                                key: ValueKey(doc.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  await _delete(doc);
                                  return false;
                                },
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _colorFor(doc.documentType)
                                          .withValues(alpha: 0.12),
                                      child: Icon(
                                        _iconFor(doc.documentType),
                                        color: _colorFor(doc.documentType),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      doc.originalFilename ??
                                          _formatDocType(doc.documentType),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            _verificationBadge(
                                                doc.verificationStatus),
                                            const SizedBox(width: 6),
                                            _ocrBadge(doc.ocrStatus),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            if (doc.financialYear != null)
                                              'FY ${doc.financialYear}',
                                            DateFormat('d MMM y')
                                                .format(doc.createdAt.toLocal()),
                                          ].join(' · '),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    trailing: doc.verificationStatus != 'VERIFIED'
                                        ? IconButton(
                                            icon: const Icon(
                                                Icons.verified_rounded,
                                                color: AppColors.primary),
                                            tooltip: 'Mark verified',
                                            onPressed: () => _verify(doc),
                                          )
                                        : const Icon(Icons.check_circle_rounded,
                                            color: AppColors.success),
                                    isThreeLine: true,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
