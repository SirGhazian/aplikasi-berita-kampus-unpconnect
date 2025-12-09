import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../theme.dart';
import '../../utils/search_field.dart';
import '../../utils/postingan_card.dart';
import '../../utils/alert_card.dart';
import '../../utils/audio_helper.dart';
import '../../services/firestore_service.dart';
import '../../models/postingan_model.dart';
import '../../postingan/lihat_postingan.dart';

class KelolaPostinganMahasiswa extends StatefulWidget {
  const KelolaPostinganMahasiswa({super.key});

  @override
  State<KelolaPostinganMahasiswa> createState() =>
      _KelolaPostinganMahasiswaState();
}

class _KelolaPostinganMahasiswaState extends State<KelolaPostinganMahasiswa> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _handleDeletePost(String postId) async {
    showDialog(
      context: context,
      builder: (context) => AlertCard(
        title: "Perhatian",
        content: "Anda yakin ingin menghapus postingan ini?",
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          Navigator.pop(context); // Close dialog
          try {
            await FirestoreService().deletePost(postId, 'berita_mahasiswa');
            if (mounted) {
              AudioHelper.playSuccess();
              toastification.show(
                context: context,
                type: ToastificationType.success,
                style: ToastificationStyle.flat,
                alignment: Alignment.topLeft,
                title: const Text("Postingan berhasil dihapus"),
                autoCloseDuration: const Duration(seconds: 3),
              );
            }
          } catch (e) {
            if (mounted) {
              AudioHelper.playError();
              toastification.show(
                context: context,
                type: ToastificationType.error,
                style: ToastificationStyle.flat,
                alignment: Alignment.topLeft,
                title: Text("Gagal menghapus postingan: $e"),
                autoCloseDuration: const Duration(seconds: 3),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER DAN SEARCH BAR
              SearchFieldWithHeader(
                title: "Kelola Postingan Mahasiswa",
                controller: _searchController,
              ),

              const SizedBox(height: 20),

              // TOMBOL EDIT POSTINGAN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _toggleEditMode,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isEditing ? textSecondary : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEditing ? Icons.close : Icons.edit,
                          size: 18,
                          color: _isEditing ? Colors.white : textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing
                              ? "Batal Edit Postingan"
                              : "Edit Postingan",
                          style: semibold.copyWith(
                            fontSize: 14,
                            color: _isEditing ? Colors.white : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // LIST POSTINGAN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<PostinganModel>>(
                  stream: FirestoreService().getBeritaMahasiswa(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    final posts = snapshot.data ?? [];

                    // FILTER POST
                    final filteredPosts = posts.where((post) {
                      return post.judul.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredPosts.isEmpty) {
                      return Center(
                        child: Text(
                          "Belum ada postingan mahasiswa",
                          style: regular.copyWith(color: textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        const collectionName = 'berita_mahasiswa';

                        return Column(
                          children: [
                            PostinganCard(
                              title: post.judul,
                              tag: post.tag,
                              uidPengunggah: post.tag == null
                                  ? post.uidPengunggah
                                  : null,
                              date:
                                  DateFormat(
                                    'd MMMM yyyy (HH:mm WIB)',
                                    'id_ID',
                                  ).format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      post.createdAt,
                                    ),
                                  ),
                              image: post.thumbnail,
                              margin: _isEditing
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.only(bottom: 16),
                              borderRadius: _isEditing
                                  ? const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    )
                                  : BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LihatPostingan(
                                      image: post.thumbnail,
                                      title: post.judul,
                                      date:
                                          DateFormat(
                                            'd MMMM yyyy (HH:mm WIB)',
                                            'id_ID',
                                          ).format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                              post.createdAt,
                                            ),
                                          ),
                                      content: post.deskripsi,
                                      uidPengunggah: post.uidPengunggah,
                                      postId: post.id,
                                      collectionName: collectionName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (_isEditing)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _handleDeletePost(post.id),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: dangerColor,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(16),
                                              bottomRight: Radius.circular(16),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Hapus Postingan",
                                            style: semibold.copyWith(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
