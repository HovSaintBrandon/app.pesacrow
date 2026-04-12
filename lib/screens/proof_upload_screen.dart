import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../core/notifications.dart';
import '../services/logger_service.dart';

class ProofUploadScreen extends StatefulWidget {
  final String transactionId;

  const ProofUploadScreen({super.key, required this.transactionId});

  @override
  State<ProofUploadScreen> createState() => _ProofUploadScreenState();
}

class _ProofUploadScreenState extends State<ProofUploadScreen> {
  File? _image;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      if (mounted) setState(() => _image = File(image.path));
    }
  }

  Future<void> _upload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_image != null) {
        await ApiService.uploadProof(widget.transactionId, _image!);
      }
      await ApiService.markDelivered(widget.transactionId);
      
      if (!mounted) return;
      AppNotifications.showSuccess(context, _image != null ? 'Proof Uploaded & Marked Delivered' : 'Marked as Delivered');
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Proof')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Proof of Delivery/Service',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Snap a photo of the shipping receipt or the delivered product to secure your payout.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (_image != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No image selected',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _loading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182CE),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_image != null ? 'Upload Proof & Mark Delivered' : 'Skip Proof & Mark Delivered'),
            ),
          ],
        ),
      ),
    );
  }
}
