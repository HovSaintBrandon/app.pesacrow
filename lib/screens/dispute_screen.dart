import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import '../core/notifications.dart';

class DisputeScreen extends StatefulWidget {
  final String transactionId;

  const DisputeScreen({super.key, required this.transactionId});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _reasonCtrl = TextEditingController();
  final List<File> _proofs = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      if (mounted) setState(() => _proofs.add(File(image.path)));
    }
  }

  Future<void> _submitDispute() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Please provide a reason for the dispute.');
      return;
    }

    LoggerService.logEvent('DISPUTE_SUBMIT_ATTEMPT', {
      'transactionId': widget.transactionId,
      'reason_len': reason.length,
      'proof_count': _proofs.length,
    });
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.disputeDeal(widget.transactionId, reason);
      
      // Upload proofs if any
      for (var file in _proofs) {
        await ApiService.uploadProof(widget.transactionId, file);
      }
      
      if (!mounted) return;
      LoggerService.logEvent('DISPUTE_SUBMIT_SUCCESS', {'transactionId': widget.transactionId});
      AppNotifications.showSuccess(context, 'Dispute Raised Successfully');
      Navigator.pop(context, true);
    } catch (e) {
      LoggerService.logError('Dispute submission failed', e);
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Raise Dispute')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What went wrong?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please describe the issue in detail. An admin will review this transaction.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _reasonCtrl,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Reason for Dispute',
                hintText: 'e.g. Item was broken, Never received service, etc.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Proof of Issue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAddProofButton(Icons.camera_alt_outlined, 'Camera',
                    () => _pickImage(ImageSource.camera)),
                const SizedBox(width: 12),
                _buildAddProofButton(Icons.photo_library_outlined, 'Gallery',
                    () => _pickImage(ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 16),
            if (_proofs.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _proofs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _buildProofThumb(i),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 14)),
            ],
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _loading ? null : _submitDispute,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Raise Official Dispute'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProofButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }

  Widget _buildProofThumb(int i) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(_proofs[i]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _proofs.removeAt(i)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
