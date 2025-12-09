import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../postingan/lihat_pengunggah.dart';
import '../services/user_session.dart';

class HalamanProfilFollower extends StatefulWidget {
  final String uid;
  final int initialIndex; // 0 untuk Followers, 1 untuk Following

  const HalamanProfilFollower({
    super.key,
    required this.uid,
    this.initialIndex = 0,
  });

  @override
  State<HalamanProfilFollower> createState() => _HalamanProfilFollowerState();
}

class _HalamanProfilFollowerState extends State<HalamanProfilFollower>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _user = UserModel.fromMap(doc.data()!);
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          _user?.nama ?? "Profil",
          style: semibold.copyWith(fontSize: 16, color: textPrimary),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryColor,
          labelStyle: semibold.copyWith(fontSize: 14),
          tabs: const [
            Tab(text: "Followers"),
            Tab(text: "Following"),
          ],
        ),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text("User tidak ditemukan"))
          : TabBarView(
              controller: _tabController,
              children: [
                _UserList(uids: List<String>.from(_user!.listFollowers)),
                _UserList(uids: List<String>.from(_user!.listFollowing)),
              ],
            ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<String> uids;

  const _UserList({required this.uids});

  String _getReadableRole(String role) {
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

  @override
  Widget build(BuildContext context) {
    if (uids.isEmpty) {
      return Center(
        child: Text(
          "Belum ada data",
          style: regular.copyWith(color: textSecondary),
        ),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: FirestoreService().getUsersByIds(uids),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Text(
              "Data tidak ditemukan",
              style: regular.copyWith(color: textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isCurrentUser = UserSession.currentUser?.uid == user.uid;

            return GestureDetector(
              onTap: () {
                if (!isCurrentUser) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LihatPengunggah(uid: user.uid),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: textSecondary.withAlpha((0.2 * 255).round()),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: CachedNetworkImage(
                        imageUrl: user.fotoProfil,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nama,
                            style: semibold.copyWith(
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_getReadableRole(user.role)} - ${user.prodi}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: regular.copyWith(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
