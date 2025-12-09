import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import '../services/user_session.dart';
import '../models/user_model.dart';
import '../auth/halaman_login.dart';
import '../utils/postingan_card.dart';
import '../models/postingan_model.dart';
import '../services/firestore_service.dart';
import '../postingan/lihat_postingan.dart';
import 'halaman_profil_postingan.dart';
import 'pengajuan_ganto.dart';
import 'halaman_profil_follower.dart';

import 'halaman_profil_edit.dart';

class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

String getReadableRole(String role) {
  switch (role) {
    case "mhs-guest":
      return "Mahasiswa";
    case "mhs-ganto":
      return "Anggota GANTO";
    case "dosen":
      return "Dosen";
    case "admin":
      return "Admin";
    default:
      return role;
  }
}

class _HalamanProfilState extends State<HalamanProfil> {
  UserModel? user;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    user = UserSession.currentUser;
  }

  Future<void> _reloadUser() async {
    final current = UserSession.currentUser;
    if (current == null) return;

    setState(() {
      loading = true;
    });

    try {
      // VALIDASI UPDATE
      await FirestoreService().validateAndUpdateUserPosts(
        current.uid,
        current.role,
      );

      // Fetch updated user data
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .get();

      if (doc.exists) {
        final data = UserModel.fromMap(doc.data()!);
        UserSession.currentUser = data;
        setState(() {
          user = data;
        });
      }
    } catch (_) {}

    setState(() {
      loading = false;
    });
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: semibold.copyWith(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: regular.copyWith(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("User belum login"));
    }

    final followerCount = user!.followers;
    final followingCount = user!.following;
    final postingCount = user!.listPostingan.length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _reloadUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER PROFIL
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: user!.fotoProfil,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Image.asset(
                              "assets/images/photo_profile.png",
                              width: 70,
                              height: 70,
                            ),
                            errorWidget: (_, __, ___) => Image.asset(
                              "assets/images/photo_profile.png",
                              width: 70,
                              height: 70,
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user!.nama,
                                style: semibold.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${user!.prodi}",
                                style: regular.copyWith(
                                  color: textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  getReadableRole(user!.role),
                                  style: regular.copyWith(
                                    fontSize: 11,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HalamanProfilEdit(),
                              ),
                            );
                            if (result == true) {
                              _reloadUser();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Edit Profil",
                              style: regular.copyWith(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Text(
                      user!.bio,
                      style: regular.copyWith(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HalamanProfilFollower(
                                    uid: user!.uid,
                                    initialIndex: 0,
                                  ),
                                ),
                              );
                            },
                            child: _statItem("$followerCount", "Followers"),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          _statItem("$postingCount", "Posts"),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HalamanProfilFollower(
                                    uid: user!.uid,
                                    initialIndex: 1,
                                  ),
                                ),
                              );
                            },
                            child: _statItem("$followingCount", "Following"),
                          ),
                        ],
                      ),
                    ),

                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // POSTINGAN SAYA (Conditional)
              if (user!.role == 'mhs-guest')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: user!.statusVerifikasiGanto == 'pending'
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PengajuanGanto(),
                              ),
                            ).then((_) => _reloadUser());
                          },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: user!.statusVerifikasiGanto == 'pending'
                            ? Colors.grey
                            : primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user!.statusVerifikasiGanto == 'pending'
                            ? "Menunggu Verifikasi"
                            : "Pengajuan Anggota Ganto",
                        style: semibold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Postingan Saya",
                        style: semibold.copyWith(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const HalamanProfilPostingan(),
                            ),
                          );
                        },
                        child: Text(
                          "Lihat Semua Postingan",
                          style: medium.copyWith(
                            fontSize: 12,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StreamBuilder<List<PostinganModel>>(
                    stream: FirestoreService().getUserPosts(
                      user!.uid,
                      user!.role,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }

                      final posts = snapshot.data ?? [];

                      if (posts.isEmpty) {
                        return Text(
                          "Belum ada postingan",
                          style: regular.copyWith(color: textSecondary),
                        );
                      }

                      return Column(
                        children: posts.map((post) {
                          return PostinganCard(
                            title: post.judul,
                            tag: post.tag,
                            uidPengunggah: post.tag == null
                                ? post.uidPengunggah
                                : null,
                            date: DateFormat('d MMMM yyyy (HH:mm WIB)', 'id_ID')
                                .format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    post.createdAt,
                                  ),
                                ),
                            image: post.thumbnail,
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
                                    collectionName: user!.role == 'dosen'
                                        ? 'berita_kampus'
                                        : 'berita_mahasiswa',
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // TOMBOL LOGOUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    UserSession.currentUser = null;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HalamanLogin()),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: dangerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Logout",
                      style: semibold.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
