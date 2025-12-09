import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import '../../services/user_session.dart';
import '../../models/user_model.dart';
import '../../auth/halaman_login.dart';
import '../../services/firestore_service.dart';

class ProfilAdmin extends StatefulWidget {
  const ProfilAdmin({super.key});

  @override
  State<ProfilAdmin> createState() => _ProfilAdminState();
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

class _ProfilAdminState extends State<ProfilAdmin> {
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
      // VALIDASI UPDATE DAN TOTAL POST
      await FirestoreService().validateAndUpdateUserPosts(
        current.uid,
        current.role,
      );

      // FETCH UPDATED
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

  Widget _buildStatCard(
    String title,
    String count,
    Color color,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: semibold.copyWith(fontSize: 20, color: textPrimary),
              ),
              Text(
                title,
                style: regular.copyWith(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("User belum login"));
    }

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
                            width: 58,
                            height: 58,
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

                    const SizedBox(height: 10),

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

              // STATISTIK DASHBOARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text("Statistik", style: semibold.copyWith(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(height: 1.2, color: Colors.black12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<Map<String, int>>(
                  stream: FirestoreService().getAdminStatistics(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    final stats =
                        snapshot.data ??
                        {
                          'dosenPosts': 0,
                          'mahasiswaPosts': 0,
                          'dosenUsers': 0,
                          'mahasiswaUsers': 0,
                          'gantoMembers': 0,
                        };

                    return Column(
                      children: [
                        _buildStatCard(
                          "Postingan Kampus",
                          stats['dosenPosts'].toString(),
                          Colors.blue,
                          Icons.article,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          "Postingan Mahasiswa",
                          stats['mahasiswaPosts'].toString(),
                          Colors.orange,
                          Icons.article_outlined,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          "Total Dosen",
                          stats['dosenUsers'].toString(),
                          Colors.purple,
                          Icons.school,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          "Total Mahasiswa",
                          stats['mahasiswaUsers'].toString(),
                          Colors.green,
                          Icons.people,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          "Total Anggota GANTO",
                          stats['gantoMembers'].toString(),
                          primaryColor,
                          Icons.newspaper,
                          fullWidth: true,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

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
