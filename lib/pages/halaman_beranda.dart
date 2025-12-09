import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../utils/postingan_card.dart';
import '../services/firestore_service.dart';
import '../services/user_session.dart';
import '../models/postingan_model.dart';
import '../postingan/lihat_postingan.dart';
import '../utils/postingan_hangat_card.dart';

class HalamanBeranda extends StatelessWidget {
  const HalamanBeranda({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================
            // HEADER (Foto + ucapan)
            // ============================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  // FOTO PROFIL
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: CachedNetworkImage(
                      imageUrl:
                          UserSession.currentUser?.fotoProfil ??
                          "https://i.pinimg.com/564x/47/ab/e9/47abe90aaea457e9157cc019ccfeb439.jpg",
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,

                      // placeholder → photo_profile
                      placeholder: (context, url) => Image.asset(
                        "assets/images/photo_profile.png",
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                      ),

                      // jika gagal
                      errorWidget: (context, error, stackTrace) => Image.asset(
                        "assets/images/photo_profile.png",
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // GREETING
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selamat Datang!",
                        style: semibold.copyWith(
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(DateTime.now()),
                        style: regular.copyWith(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============================
            // SEARCH BAR
            // ============================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Cari Artikel",
                            hintStyle: regular.copyWith(color: textSecondary),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 55,
                        height: 55,
                        color: primaryColor,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =====================
            // ARTIKEL HANGAT
            // =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    "Artikel Hangat",
                    style: semibold.copyWith(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(height: 1.2, color: Colors.black12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 260,
              child: StreamBuilder<List<PostinganModel>>(
                stream: FirestoreService().getAllPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada artikel hangat'),
                    );
                  }

                  // SORTING MAKSIMAL 5 POSTINGAN
                  final sortedPosts = snapshot.data!
                    ..sort((a, b) => b.views.compareTo(a.views));
                  final topPosts = sortedPosts.take(5).toList();

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20),
                    itemCount: topPosts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final post = topPosts[index];
                      // JIKA tag ADA, MAKA berita_kampus
                      final collectionName = post.tag != null
                          ? 'berita_kampus'
                          : 'berita_mahasiswa';
                      return GestureDetector(
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
                        child: PostinganHangatCard(
                          img: post.thumbnail,
                          title: post.judul,
                          uidPengunggah: post.uidPengunggah,
                          date: DateFormat('d MMMM yyyy', 'id_ID').format(
                            DateTime.fromMillisecondsSinceEpoch(post.createdAt),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // =====================
            // ARTIKEL TERBARU
            // =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    "Artikel Terbaru",
                    style: semibold.copyWith(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(height: 1.2, color: Colors.black12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<PostinganModel>>(
                stream: FirestoreService().getAllPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada artikel terbaru'),
                    );
                  }

                  // SORT TERBARU DAN MAKSIMAL 5
                  final sortedPosts = snapshot.data!
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  final latestPosts = sortedPosts.take(5).toList();

                  return Column(
                    children: latestPosts.map((post) {
                      // tag berita_kampus
                      final collectionName = post.tag != null
                          ? 'berita_kampus'
                          : 'berita_mahasiswa';

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
                                collectionName: collectionName,
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
