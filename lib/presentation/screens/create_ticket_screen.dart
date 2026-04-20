import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../../core/constants/supabase_constants.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  String _priority   = SupabaseConstants.priorityMedium;
  XFile? _pickedFile; 
  bool   _loading    = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source, 
        imageQuality: 70,
        // Hint untuk web agar lebih mengutamakan kamera jika memungkinkan
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked != null) {
        setState(() => _pickedFile = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengambil gambar: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tambah Lampiran',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil dari kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_pickedFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
                title: const Text('Hapus lampiran',
                    style: TextStyle(color: AppTheme.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _pickedFile = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      Uint8List? bytes;
      String? fileName;
      
      if (_pickedFile != null) {
        bytes = await _pickedFile!.readAsBytes();
        fileName = _pickedFile!.name;
      }

      await ref.read(ticketActionsProvider).createTicket(
            title:       _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            priority:    _priority,
            attachmentBytes: bytes,
            fileName: fileName,
          );
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiket berhasil dibuat!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat tiket: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Buat Tiket Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Masalah *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi *',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              Text('Prioritas', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  SupabaseConstants.priorityLow,
                  SupabaseConstants.priorityMedium,
                  SupabaseConstants.priorityHigh,
                ].map((p) {
                  final isSelected = _priority == p;
                  final color = AppTheme.priorityColor(p);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.1) : theme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? color : theme.dividerColor),
                          ),
                          child: Text(
                            AppTheme.priorityLabel(p),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? color : theme.hintColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Lampiran (opsional)', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showAttachmentOptions,
                child: Container(
                  height: _pickedFile != null ? 180 : 80,
                  decoration: BoxDecoration(
                    color: theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: _pickedFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: kIsWeb 
                                ? Image.network(_pickedFile!.path, fit: BoxFit.cover)
                                : Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
                            ),
                            Positioned(top: 8, right: 8, child: IconButton.filled(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() => _pickedFile = null),
                            )),
                          ],
                        )
                      : const Center(child: Icon(Icons.add_a_photo_outlined)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Kirim Tiket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
