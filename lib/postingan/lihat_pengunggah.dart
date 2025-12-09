import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/postingan_model.dart';
import '../utils/postingan_card.dart';
import 'lihat_postingan.dart';
import '../services/user_session.dart';
import '../pages/halaman_profil_follower.dart';

class LihatPengunggah extends StatefulWidget {
  final String uid;

  const LihatPengunggah({super.key, required this.uid});

  @override
  State<LihatPengunggah> createState() => _LihatPengunggahState();
}

class _LihatPengunggahState extends State<LihatPengunggah> {
  UserModel? user;
  bool isLoading = true;
  bool isFollowing = false; // UI state

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      final currentUser = UserSession.currentUser;
      bool followingStatus = false;

      if (currentUser != null) {
        followingStatus = await FirestoreService().isFollowing(
          currentUser.uid,
          widget.uid,
        );
      }

      if (doc.exists) {
        setState(() {
          user = UserModel.fromMap(doc.data()!);
          isFollowing = followingStatus;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = UserSession.currentUser;
    if (currentUser == null || user == null) return;

    // Optimistic update
    setState(() {
      isFollowing = !isFollowing;
      if (isFollowing) {
        user = user!.copyWith(
          listFollowers: [...user!.listFollowers, currentUser.uid],
        );
      } else {
        final newFollowers = List.from(user!.listFollowers);
        newFollowers.remove(currentUser.uid);
        user = user!.copyWith(listFollowers: newFollowers);
      }
    });

    try {
      if (isFollowing) {
        await FirestoreService().followUser(currentUser.uid, widget.uid);
        // Update local session
        final newFollowing = [...currentUser.listFollowing, widget.uid];
        UserSession.currentUser = currentUser.copyWith(
          listFollowing: newFollowing,
        );
      } else {
        await FirestoreService().unfollowUser(currentUser.uid, widget.uid);
        // Update local session
        final newFollowing = List.from(currentUser.listFollowing);
        newFollowing.remove(widget.uid);
        UserSession.currentUser = currentUser.copyWith(
          listFollowing: newFollowing,
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        isFollowing = !isFollowing;
        // re-fetch
        if (isFollowing) {
          user = user!.copyWith(
            listFollowers: [...user!.listFollowers, currentUser.uid],
          );
        } else {
          final newFollowers = List.from(user!.listFollowers);
          newFollowers.remove(currentUser.uid);
          user = user!.copyWith(listFollowers: newFollowers);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memproses: $e")));
      }
    }
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Profil Pengunggah",
          style: semibold.copyWith(color: textPrimary),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? const Center(child: Text("User tidak ditemukan"))
          : SingleChildScrollView(
              child: Column(
                children: [
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
                                    "${user!.prodi} - ${user!.fakultas}",
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
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user!.bio,
                          style: regular.copyWith(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                      builder: (context) =>
                                          HalamanProfilFollower(
                                            uid: user!.uid,
                                            initialIndex: 0,
                                          ),
                                    ),
                                  );
                                },
                                child: _statItem(
                                  "${user!.followers}",
                                  "Followers",
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24,
                              ),
                              _statItem(
                                "${user!.listPostingan.length}",
                                "Posts",
                              ),
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
                                      builder: (context) =>
                                          HalamanProfilFollower(
                                            uid: user!.uid,
                                            initialIndex: 1,
                                          ),
                                    ),
                                  );
                                },
                                child: _statItem(
                                  "${user!.following}",
                                  "Following",
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (UserSession.currentUser?.uid != widget.uid)
                          GestureDetector(
                            onTap: _toggleFollow,
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isFollowing
                                    ? Colors.grey[300]
                                    : primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isFollowing ? "Following" : "Follow",
                                style: semibold.copyWith(
                                  color: isFollowing
                                      ? textPrimary
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // POSTINGAN LIST
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Postingan",
                          style: semibold.copyWith(fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(height: 1.2, color: Colors.black12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: StreamBuilder<List<PostinganModel>>(
                      stream: FirestoreService().getUserPosts(
                        user!.uid,
                        user!.role,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
