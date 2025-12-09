import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:toastification/toastification.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../services/user_session.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/audio_helper.dart';

class HalamanProfilEdit extends StatefulWidget {
  const HalamanProfilEdit({super.key});

  @override
  State<HalamanProfilEdit> createState() => _HalamanProfilEditState();
}

class _HalamanProfilEditState extends State<HalamanProfilEdit> {
  late TextEditingController _namaController;
  late TextEditingController _bioController;
  File? _selectedImage;
  bool _isLoading = false;
  final UserModel? _currentUser = UserSession.currentUser;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: _currentUser?.nama ?? '');
    _bioController = TextEditingController(text: _currentUser?.bio ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService().uploadImage(
          _selectedImage!,
          'user-foto-profil',
        );
      }

      final updatedData = <String, dynamic>{
        'nama': _namaController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      if (imageUrl != null) {
        updatedData['fotoProfil'] = imageUrl;
      }

      await FirestoreService().updateUser(_currentUser.uid, updatedData);

      // Update local session
      final updatedUser = _currentUser.copyWith(
        nama: updatedData['nama'],
        bio: updatedData['bio'],
        fotoProfil: imageUrl ?? _currentUser.fotoProfil,
      );
      UserSession.currentUser = updatedUser;

      if (mounted) {
        AudioHelper.playSuccess();
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: const Text("Profil berhasil diperbarui"),
          autoCloseDuration: const Duration(seconds: 3),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AudioHelper.playError();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: Text("Gagal memperbarui profil: $e"),
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
          "Edit Profil",
          style: semibold.copyWith(fontSize: 16, color: textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO PROFIL
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: _currentUser?.fotoProfil ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[300]),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // FIELD NAMA
            Text(
              "Nama",
              style: medium.copyWith(fontSize: 16, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: textSecondary.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: TextField(
                controller: _namaController,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [TitleCaseFormatter()],
                style: regular.copyWith(fontSize: 14, color: textPrimary),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // FIELD BIO
            Text(
              "Bio",
              style: medium.copyWith(fontSize: 16, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: textSecondary.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 4,
                style: regular.copyWith(fontSize: 14, color: textPrimary),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // TOMBOL SAVE
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Simpan Perubahan",
                            style: semibold.copyWith(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text;
    List<String> words = text.split(' ');
    List<String> capitalizedWords = [];

    for (String word in words) {
      if (word.isNotEmpty) {
        capitalizedWords.add(
          word[0].toUpperCase() + word.substring(1).toLowerCase(),
        );
      } else {
        capitalizedWords.add('');
      }
    }

    String newText = capitalizedWords.join(' ');

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
