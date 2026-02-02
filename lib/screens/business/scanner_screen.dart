import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/deal_model.dart';
import 'package:sara_fun/services/referral_engine.dart';
import 'package:gap/gap.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _isProcessing = false;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _handleScan(barcode.rawValue!);
        break; // Process only the first valid code
      }
    }
  }

  Future<void> _handleScan(String clientUid) async {
    setState(() => _isProcessing = true);
    _controller?.stop();

    try {
      // 1. Fetch Client Data
      final firebaseService = ref.read(firebaseServiceProvider);
      final client = await firebaseService.getUser(clientUid);

      if (client == null || client.role != UserRole.client) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid Client QR")),
          );
          _resumeScan();
        }
        return;
      }

      if (mounted) {
        _showDealDialog(client);
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
        _resumeScan();
      }
    }
  }

  void _resumeScan() {
    setState(() => _isProcessing = false);
    _controller?.start();
  }

  Future<void> _showDealDialog(AppUser client) async {
    final priceController = TextEditingController();
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("New Deal with Client", style: Theme.of(context).textTheme.titleLarge),
            const Gap(8),
            Text("Client ID: ${client.uid.substring(0,6)}..."),
            const Gap(16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: "Total Price (Stars)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: () => _processTransaction(client, priceController.text),
              child: const Text("Process Transaction"),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
    
    // After dialog closes (if not processed), resume scan?
    // If navigation happened in _process, this won't matter.
    if (mounted && !_isProcessing) {
        // If we came back without processing
    }
  }

  Future<void> _processTransaction(AppUser client, String priceStr) async {
    final amount = int.tryParse(priceStr);
    if (amount == null || amount <= 0) return;

    final navigator = GoRouter.of(context); // Capture navigator before async
    Navigator.pop(context); // Close sheet

    try {
      final master = ref.read(currentUserProvider).value!; // Assume loaded
      final firebaseService = ref.read(firebaseServiceProvider);

      // Core Logic: 20% Rule
      if (!ReferralEngine.hasSufficientDeposit(master, amount)) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Insufficient Deposit Balance!")),
        );
        _resumeScan();
        return;
      }

      final distribution = ReferralEngine.calculateDistribution(amount, client, master);
      
      final deal = Deal(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        clientId: client.uid,
        masterId: master.uid,
        serviceId: 'manual_scan',
        amountStars: amount,
        commissionDistribution: distribution.toMap(),
        createdAt: DateTime.now(),
      );

      // Execute Transaction
      await firebaseService.processDealTransaction(deal, distribution, client, master);

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deal Successful! Rewards distributed.")),
        );
        navigator.pop(); // Go back to Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Transaction Failed: $e")),
        );
        _resumeScan();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Client")),
      body: Column(
        children: [
          Expanded(
            child: kIsWeb 
              ? Center(
                  child: ElevatedButton(
                    onPressed: () => _handleScan("client-123"), // Debug Mock
                    child: const Text("Simulate Scan (Web Debug)"),
                  ),
                )
              : MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Align QR code within the frame"),
          ),
        ],
      ),
    );
  }
}
