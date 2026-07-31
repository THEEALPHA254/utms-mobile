import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _balance;
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        apiService.getWalletBalance(),
        apiService.getMyTransactions(),
      ]);
      setState(() {
        _balance = results[0] as Map<String, dynamic>;
        _transactions = results[1] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TopUpSheet(onSuccess: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      resizeToAvoidBottomInset: true,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Balance card
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Available Balance',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(
                                _balance == null
                                    ? '—'
                                    : 'KES ${double.parse(_balance!['balance'].toString()).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showTopUpSheet,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Top Up'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transaction history
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text('Transaction History',
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('No transactions yet',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _transactions.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final t = _transactions[i];
                              final isTopUp =
                                  t['transaction_type'] == 'wallet_topup';
                              final isSuccess = t['status'] == 'success';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: isTopUp
                                      ? Colors.green.shade50
                                      : Colors.blue.shade50,
                                  child: Icon(
                                    isTopUp
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isTopUp
                                        ? Colors.green
                                        : Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  isTopUp ? 'Wallet Top-Up' : 'Trip Payment',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                subtitle: Text(
                                  t['reference'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isTopUp ? '+' : '-'}KES ${t['amount']}',
                                      style: TextStyle(
                                        color: isTopUp
                                            ? Colors.green
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSuccess
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        t['status'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSuccess
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Top Up Bottom Sheet ───────────────────────────────────────────────────────

class _TopUpSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _TopUpSheet({required this.onSuccess});
  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  bool _checking = false;
  String? _message;
  bool _success = false;
  bool _stkSent = false;
  String? _pendingReference;

  final _quickAmounts = [50, 100, 200, 500];

  Future<void> _topUp() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount < 10) {
      setState(() => _message = 'Enter a valid amount (min KES 10)');
      return;
    }
    if (_phoneCtrl.text.isEmpty) {
      setState(() => _message = 'Enter your M-Pesa phone number');
      return;
    }
    setState(() { _loading = true; _message = null; });
    try {
      final res = await apiService.topUpWallet({
        'amount': amount,
        'payment_method': 'mpesa',
        'phone_number': _phoneCtrl.text.trim(),
      });
      setState(() {
        _stkSent = true;
        _pendingReference = res['reference'] as String?;
        _message = 'STK push sent. Complete payment on your phone, then tap "Confirm Payment" below.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Top-up failed. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _checkPayment() async {
    if (_pendingReference == null) return;
    setState(() { _checking = true; _message = null; });
    try {
      final res = await apiService.checkMpesaPayment(_pendingReference!);
      final status = res['status'] as String? ?? 'failed';
      final msg = res['message'] as String? ?? '';
      final balance = res['balance'] as String?;
      setState(() {
        _checking = false;
        _success = status == 'success';
        _stkSent = !_success;
        _message = _success
            ? '${msg}${balance != null ? '\nNew balance: KES $balance' : ''}'
            : msg.isNotEmpty ? msg : 'Payment not confirmed yet. Try again in a moment.';
      });
      if (_success) {
        _amountCtrl.clear();
        _phoneCtrl.clear();
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _checking = false;
        _message = 'Could not check payment status. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use SingleChildScrollView so the form scrolls up when the keyboard opens
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('Top Up Wallet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Quick amount chips
          Wrap(
            spacing: 8,
            children: _quickAmounts
                .map((a) => ActionChip(
                      label: Text('KES $a'),
                      onPressed: () =>
                          _amountCtrl.text = a.toString(),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Text(
                  'KES',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // M-Pesa phone number
          const Text('M-Pesa Payment',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (true) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone (e.g. 0712345678)',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],

          if (_message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _success
                    ? Colors.green.shade50
                    : _stkSent
                        ? Colors.blue.shade50
                        : theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_message!,
                  style: TextStyle(
                      color: _success
                          ? Colors.green.shade800
                          : _stkSent
                              ? Colors.blue.shade800
                              : theme.colorScheme.error)),
            ),
          ],

          const SizedBox(height: 20),
          if (!_stkSent)
            ElevatedButton(
              onPressed: _loading ? null : _topUp,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Proceed'),
            ),
          if (_stkSent && !_success) ...[
            ElevatedButton.icon(
              onPressed: _checking ? null : _checkPayment,
              icon: _checking
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(_checking ? 'Checking...' : 'Confirm Payment'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : _topUp,
              child: const Text('Resend STK Push'),
            ),
          ],
        ],
      ),
    );
  }
}

