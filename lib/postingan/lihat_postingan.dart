import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/user_session.dart';
import 'lihat_pengunggah.dart';

class LihatPostingan extends StatefulWidget {
  final String image;
  final String title;
  final String date;
  final String content;
  final String uidPengunggah;
  final String postId;
  final String collectionName;

  const LihatPostingan({
    super.key,
    required this.image,
    required this.title,
    required this.date,
    required this.content,
    required this.uidPengunggah,
    required this.postId,
    required this.collectionName,
  });

  @override
  State<LihatPostingan> createState() => _LihatPostinganState();
}

class _LihatPostinganState extends State<LihatPostingan> {
  UserModel? author;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAuthor();
    _incrementViewIfNeeded();
  }

  Future<void> _fetchAuthor() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uidPengunggah)
          .get();

      if (doc.exists) {
        setState(() {
          author = UserModel.fromMap(doc.data()!);
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

  Future<void> _incrementViewIfNeeded() async {
    final currentUser = UserSession.currentUser;
    if (currentUser == null) return;

    await FirestoreService().incrementView(
      postId: widget.postId,
      collectionName: widget.collectionName,
      currentUserId: currentUser.uid,
      authorId: widget.uidPengunggah,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // MAIN KONTEN
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE AT TOP
                CachedNetworkImage(
                  imageUrl: widget.image,
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Image.asset(
                    "assets/images/base_thumbnail.png",
                    height: 350,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    "assets/images/base_thumbnail.png",
                    height: 350,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // KONTEN AREA
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // JUDUL
                        Text(
                          widget.title,
                          style: semibold.copyWith(
                            fontSize: 20,
                            color: textPrimary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // AUTHOR CARD
                        GestureDetector(
                          onTap: () {
                            final currentUser = UserSession.currentUser;
                            if (currentUser != null &&
                                author != null &&
                                currentUser.uid != author!.uid) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LihatPengunggah(uid: author!.uid),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // AUTHOR AVATAR
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        author?.fotoProfil ??
                                        "https://i.pinimg.com/564x/47/ab/e9/47abe90aaea457e9157cc019ccfeb439.jpg",
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[300],
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Image.asset(
                                          "assets/images/photo_profile.png",
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // AUTHOR INFO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isLoading
                                            ? 'Loading...'
                                            : author?.nama ?? 'Unknown',
                                        style: semibold.copyWith(
                                          fontSize: 14,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.date,
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
                        ),

                        const SizedBox(height: 24),

                        // KONTEN TEKS
                        Text(
                          widget.content,
                          style: regular.copyWith(
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TOMBOL BACK
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
