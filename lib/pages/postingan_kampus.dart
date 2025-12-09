import 'package:flutter/material.dart';
import '../utils/search_field.dart';
import '../utils/postingan_card.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/postingan_model.dart';
import 'package:intl/intl.dart';
import '../postingan/lihat_postingan.dart';

class PostinganKampus extends StatefulWidget {
  const PostinganKampus({super.key});

  @override
  State<PostinganKampus> createState() => _PostinganKampusState();
}

class _PostinganKampusState extends State<PostinganKampus> {
  final TextEditingController searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String query = "";

  String _formatDate(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('d MMMM yyyy (HH:mm WIB)', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER DAN SEARCH BAR
            SearchFieldWithHeader(
              titleWidget: Row(
                children: [
                  Text("Berita Resmi UNP", style: large),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: Colors.blue, size: 20),
                ],
              ),
              controller: searchController,
              onChanged: (val) {
                setState(() {
                  query = val;
                });
              },
            ),

            const SizedBox(height: 20),

            // LIST POSTINGAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<PostinganModel>>(
                stream: _firestoreService.getBeritaKampus(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data ?? [];
                  final filtered = data.where((item) {
                    return item.judul.toLowerCase().contains(
                      query.toLowerCase(),
                    );
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text("Tidak ada berita ditemukan"),
                    );
                  }

                  return Column(
                    children: filtered.map((post) {
                      return PostinganCard(
                        title: post.judul,
                        tag: post.tag,
                        date: _formatDate(post.createdAt),
                        image: post.thumbnail,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LihatPostingan(
                                image: post.thumbnail,
                                title: post.judul,
                                date: _formatDate(post.createdAt),
                                content: post.deskripsi,
                                uidPengunggah: post.uidPengunggah,
                                postId: post.id,
                                collectionName: 'berita_kampus',
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
