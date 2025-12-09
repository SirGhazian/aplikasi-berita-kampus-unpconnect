import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../services/user_session.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../models/postingan_model.dart';
import 'package:toastification/toastification.dart';
import '../utils/audio_helper.dart';

class TambahPostingan extends StatefulWidget {
  const TambahPostingan({super.key});

  @override
  State<TambahPostingan> createState() => _TambahPostinganState();
}

class _TambahPostinganState extends State<TambahPostingan> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _kontenController = TextEditingController();
  final TextEditingController _thumbnailController = TextEditingController();

  String dropdownValue = "FT UNP";
  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final List<String> _fakultasOptions = [
    "FT UNP",
    "FMIPA UNP",
    "FIP UNP",
    "FBS UNP",
    "FE UNP",
    "FIS UNP",
    "FIK UNP",
    "FPP UNP",
  ];

  @override
  void dispose() {
    _judulController.dispose();
    _kontenController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // AMBIL GAMBAR GALERI
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

      // UPLOAD PRESET CLOUDINARY
      final user = UserSession.currentUser;
      if (user == null) return;

      String uploadPreset;
      if (user.role == 'dosen') {
        uploadPreset = 'unp-connect_berita-dosen';
      } else if (user.role == 'mhs-ganto') {
        uploadPreset = 'unp-connect_berita-mahasiswa';
      } else {
        // Default fallback
        uploadPreset = 'unp-connect_berita-mahasiswa';
      }

      // Upload Cloudinary role-specific preset
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

  Future<void> _handlePost() async {
    final user = UserSession.currentUser;
    if (user == null) return;

    if (_judulController.text.isEmpty || _kontenController.text.isEmpty) {
      AudioHelper.playError();
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.topLeft,
        title: const Text("Judul dan konten tidak boleh kosong"),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    // Validate image upload
    if (_uploadedImageUrl == null) {
      AudioHelper.playError();
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.topLeft,
        title: const Text("Silakan pilih dan upload gambar terlebih dahulu"),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String collectionName = "";
      String? tag;
      String? fakultas;
      String? prodi;

      if (user.role == 'dosen') {
        collectionName = 'berita_kampus';
        tag = dropdownValue;
        fakultas = dropdownValue.replaceAll(" UNP", "");
        prodi = user.prodi;
      } else if (user.role == 'mhs-ganto') {
        collectionName = 'berita_mahasiswa';
        tag = null;
        fakultas = null;
        prodi = null;
      } else {
        AudioHelper.playError();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: const Text("Anda tidak memiliki akses untuk memposting"),
          autoCloseDuration: const Duration(seconds: 3),
        );
        setState(() => _isLoading = false);
        return;
      }

      final newPost = PostinganModel(
        id: "", // generated by Firestore
        judul: _judulController.text,
        thumbnail: _uploadedImageUrl!, // Cloudinary URL
        deskripsi: _kontenController.text,
        uidPengunggah: user.uid,
        fakultas: fakultas,
        prodi: prodi,
        tag: tag,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await FirestoreService().addPost(newPost, collectionName);

      if (mounted) {
        AudioHelper.playSuccess();
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: const Text("Postingan berhasil ditambahkan"),
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
          title: Text("Gagal memposting: $e"),
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
    final user = UserSession.currentUser;
    final isDosen = user?.role == 'dosen';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: CachedNetworkImage(
                      imageUrl: user?.fotoProfil ?? "",
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nama ?? "Guest",
                        style: semibold.copyWith(fontSize: 16),
                      ),
                      Text(
                        user?.prodi ?? "-",
                        style: regular.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 30,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

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
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

              const SizedBox(height: 20),

              // INPUT JUDUL
              TextField(
                controller: _judulController,
                decoration: InputDecoration(
                  hintText: "Masukkan Judul",
                  hintStyle: regular.copyWith(color: textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: textSecondary, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: textSecondary, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(height: 1, color: Colors.black12),

              const SizedBox(height: 20),

              // TEXTAREA KONTEN
              TextField(
                controller: _kontenController,
                minLines: 5,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: "Tulis sesuatu di sini...",
                  hintStyle: regular.copyWith(color: textSecondary),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textSecondary, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textSecondary, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  // ================================
                  // DROPDOWN (DOSEN)
                  // ================================
                  if (isDosen)
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: dropdownValue,
                            isDense: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                            ),
                            style: semibold.copyWith(
                              fontSize: 15,
                              color: textPrimary,
                            ),
                            items: _fakultasOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  dropdownValue = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // TOMBOL POST
                  GestureDetector(
                    onTap: _isLoading ? null : _handlePost,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
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
                                "Post",
                                style: semibold.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
