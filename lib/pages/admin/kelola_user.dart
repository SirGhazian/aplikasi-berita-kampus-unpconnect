import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:toastification/toastification.dart';
import '../../theme.dart';
import '../../utils/search_field.dart';
import '../../utils/alert_card.dart';
import '../../utils/audio_helper.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

import 'tambah_user.dart';

class KelolaUser extends StatefulWidget {
  const KelolaUser({super.key});

  @override
  State<KelolaUser> createState() => _KelolaUserState();
}

String getReadableRole(String role) {
  switch (role) {
    case "mhs-guest":
      return "Mahasiswa (Guest)";
    case "mhs-ganto":
      return "Anggota Ganto";
    case "dosen":
      return "Dosen";
    case "admin":
      return "Admin";
    default:
      return role;
  }
}

class _KelolaUserState extends State<KelolaUser> {
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

  Future<void> _handleDeleteUser(String uid) async {
    showDialog(
      context: context,
      builder: (context) => AlertCard(
        title: "Perhatian",
        content:
            "Anda yakin ingin menghapus user ini? Semua postingan user ini juga akan dihapus.",
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          Navigator.pop(context); // TUTUP DIALOG
          try {
            await FirestoreService().deleteUser(uid);
            if (mounted) {
              AudioHelper.playSuccess();
              toastification.show(
                context: context,
                type: ToastificationType.success,
                style: ToastificationStyle.flat,
                alignment: Alignment.topLeft,
                title: const Text("User berhasil dihapus"),
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
                title: Text("Gagal menghapus user: $e"),
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
                title: "Kelola User",
                controller: _searchController,
              ),

              const SizedBox(height: 20),

              // TOMBOL ACTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleEditMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isEditing
                                ? textSecondary
                                : Colors.grey[300],
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
                                _isEditing ? "Batal" : "Edit User",
                                style: semibold.copyWith(
                                  fontSize: 14,
                                  color: _isEditing
                                      ? Colors.white
                                      : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TambahUser(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Tambah User",
                                style: semibold.copyWith(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // LIST USER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<UserModel>>(
                  stream: FirestoreService().getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    final users = snapshot.data ?? [];

                    // FILTER USER
                    final filteredUsers = users.where((user) {
                      return user.nama.toLowerCase().contains(_searchQuery) ||
                          user.uid.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Text(
                          "Belum ada user",
                          style: regular.copyWith(color: textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];

                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: _isEditing
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: _isEditing
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      )
                                    : BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  // FOTO PROFIL
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: CachedNetworkImage(
                                      imageUrl: user.fotoProfil,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(color: Colors.grey[300]),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // INFO USER
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.nama,
                                          style: semibold.copyWith(
                                            fontSize: 14,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.uid, // NIM/NIP
                                          style: regular.copyWith(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withAlpha(
                                              (0.1 * 255).round(),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            getReadableRole(
                                              user.role,
                                            ).toUpperCase(),
                                            style: semibold.copyWith(
                                              fontSize: 10,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isEditing)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            _handleDeleteUser(user.uid),
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
                                            "Hapus User",
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
