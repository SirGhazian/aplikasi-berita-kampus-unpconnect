import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:toastification/toastification.dart';
import '../theme.dart';
import '../models/postingan_model.dart';
import '../services/firestore_service.dart';
import '../services/user_session.dart';
import '../services/cloudinary_service.dart';
import '../utils/audio_helper.dart';

class EditPostingan extends StatefulWidget {
  final PostinganModel post;
  final String collectionName;

  // edit
  const EditPostingan({
    super.key,
    required this.post,
    required this.collectionName,
  });

  // teruskan
  @override
  State<EditPostingan> createState() => _EditPostinganState();
}

class _EditPostinganState extends State<EditPostingan> {
  late TextEditingController _judulController;
  late TextEditingController _kontenController;

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
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.post.judul);
    _kontenController = TextEditingController(text: widget.post.deskripsi);
    _uploadedImageUrl = widget.post.thumbnail;

    // Set initial dropdown value
    if (_fakultasOptions.contains(widget.post.fakultas)) {
      dropdownValue = widget.post.fakultas!;
    } else if (_fakultasOptions.contains(widget.post.tag)) {
      dropdownValue = widget.post.tag!;
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _kontenController.dispose();
    super.dispose();
  }

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

      final user = UserSession.currentUser;
      if (user == null) return;

      String uploadPreset;
      if (user.role == 'dosen') {
        uploadPreset = 'unp-connect_berita-dosen';
      } else if (user.role == 'mhs-ganto') {
        uploadPreset = 'unp-connect_berita-mahasiswa';
      } else {
        uploadPreset = 'unp-connect_berita-mahasiswa';
      }

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

  Future<void> _handleUpdate() async {
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

    if (_uploadedImageUrl == null) {
      AudioHelper.playError();
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.topLeft,
        title: const Text("Thumbnail tidak boleh kosong"),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserSession.currentUser;
      String? tag;
      String? fakultas;

      if (user?.role == 'dosen') {
        tag = dropdownValue;
        fakultas = dropdownValue;
      }

      final updatedData = {
        'judul': _judulController.text,
        'deskripsi': _kontenController.text,
        'thumbnail': _uploadedImageUrl,
        if (tag != null) 'tag': tag,
        if (fakultas != null) 'fakultas': fakultas,
      };

      await FirestoreService().updatePost(
        widget.post.id,
        widget.collectionName,
        updatedData,
      );

      if (mounted) {
        AudioHelper.playSuccess();
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: const Text("Postingan berhasil diperbarui"),
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
          title: Text("Gagal memperbarui: $e"),
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
                  Expanded(
                    child: Text(
                      "Edit Postingan",
                      style: semibold.copyWith(fontSize: 20),
                    ),
                  ),
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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: _uploadedImageUrl ?? "",
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
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
                icon: const Icon(Icons.edit),
                label: const Text('Ganti Gambar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  // DROPDOWN (UNTUK DOSEN)
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

                  // TOMBOL SIMPAN
                  GestureDetector(
                    onTap: _isLoading ? null : _handleUpdate,
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
                                "Simpan",
                                style: semibold.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
