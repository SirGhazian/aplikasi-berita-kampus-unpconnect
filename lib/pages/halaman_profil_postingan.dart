import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../utils/search_field.dart';
import '../utils/postingan_card.dart';
import '../utils/alert_card.dart';
import '../services/user_session.dart';
import '../services/firestore_service.dart';
import '../models/postingan_model.dart';
import '../postingan/lihat_postingan.dart';
import '../postingan/edit_postingan.dart';
import 'package:toastification/toastification.dart';
import '../utils/audio_helper.dart';

class HalamanProfilPostingan extends StatefulWidget {
  const HalamanProfilPostingan({super.key});

  @override
  State<HalamanProfilPostingan> createState() => _HalamanProfilPostinganState();
}

class _HalamanProfilPostinganState extends State<HalamanProfilPostingan> {
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

  Future<void> _handleDeletePost(String postId, String collectionName) async {
    showDialog(
      context: context,
      builder: (context) => AlertCard(
        title: "Perhatian",
        content: "Anda yakin ingin menghapus postingan ini?",
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          Navigator.pop(context); // TUTUP DIALOG
          try {
            await FirestoreService().deletePost(postId, collectionName);
            // paksa reload
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
    final user = UserSession.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User belum login")));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER DAN SEARCH BAR
              SearchFieldWithHeader(
                title: "List Postingan",
                controller: _searchController,
              ),

              const SizedBox(height: 20),

              // Edit Postingan Button
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

              // List Postingan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<PostinganModel>>(
                  stream: FirestoreService().getUserPosts(user.uid, user.role),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    final posts = snapshot.data ?? [];

                    // Filter posts based on search query
                    final filteredPosts = posts.where((post) {
                      return post.judul.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredPosts.isEmpty) {
                      return Center(
                        child: Text(
                          "Belum ada postingan",
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
                        final collectionName = user.role == 'dosen'
                            ? 'berita_kampus'
                            : 'berita_mahasiswa';

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
                                        onTap: () => _handleDeletePost(
                                          post.id,
                                          collectionName,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: dangerColor,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(16),
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
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditPostingan(
                                                    post: post,
                                                    collectionName:
                                                        collectionName,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.only(
                                              bottomRight: Radius.circular(16),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Edit Postingan",
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
