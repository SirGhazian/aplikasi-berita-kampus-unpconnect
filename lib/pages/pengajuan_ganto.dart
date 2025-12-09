import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import '../theme.dart';
import '../services/user_session.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/audio_helper.dart';

class PengajuanGanto extends StatefulWidget {
  const PengajuanGanto({super.key});

  @override
  State<PengajuanGanto> createState() => _PengajuanGantoState();
}

class _PengajuanGantoState extends State<PengajuanGanto> {
  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isUploadingImage = true;
      });

      // preset cloudinary
      const uploadPreset = 'pengajuan-ganto';

      final imageUrl = await _cloudinaryService.uploadImage(
        _selectedImage!,
        uploadPreset,
      );

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (imageUrl == null) {
        if (mounted) {
          AudioHelper.playError();
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            title: const Text('Gagal upload gambar'),
            autoCloseDuration: const Duration(seconds: 3),
            alignment: Alignment.topLeft,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        AudioHelper.playError();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title: const Text('Error memilih gambar'),
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.topLeft,
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    final user = UserSession.currentUser;
    if (user == null) return;

    if (_uploadedImageUrl == null) {
      AudioHelper.playError();
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.topLeft,
        title: const Text("Silakan upload bukti keanggotaan"),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirestoreService().submitGantoApplication(
        user.uid,
        _uploadedImageUrl!,
      );

      if (mounted) {
        AudioHelper.playSuccess();
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: const Text("Pengajuan berhasil dikirim"),
          autoCloseDuration: const Duration(seconds: 3),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AudioHelper.playError();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: Text("Gagal mengirim pengajuan: $e"),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Pengajuan Anggota Ganto",
          style: semibold.copyWith(fontSize: 16, color: textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload Bukti Keanggotaan",
                style: semibold.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Silakan upload foto kartu anggota atau bukti lainnya yang menunjukkan Anda adalah anggota GANTO.",
                style: regular.copyWith(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // IMAGE PREVIEW & PICKER
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_isUploadingImage)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 15),

              // TOMBOL PICK IMAGE
              ElevatedButton.icon(
                onPressed: _isUploadingImage || _isLoading
                    ? null
                    : _pickAndUploadImage,
                icon: Icon(
                  _selectedImage == null
                      ? Icons.add_photo_alternate
                      : Icons.edit,
                ),
                label: Text(
                  _selectedImage == null ? 'Pilih Gambar' : 'Ganti Gambar',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: primaryColor),
                  ),
                  elevation: 0,
                ),
              ),

              if (_uploadedImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Gambar berhasil di-upload',
                        style: regular.copyWith(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              // TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _uploadedImageUrl == null
                      ? null
                      : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Kirim Pengajuan",
                          style: semibold.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
