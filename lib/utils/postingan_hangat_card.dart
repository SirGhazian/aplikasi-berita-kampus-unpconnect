import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class PostinganHangatCard extends StatefulWidget {
  final String img;
  final String title;
  final String uidPengunggah;
  final String date;

  const PostinganHangatCard({
    super.key,
    required this.img,
    required this.title,
    required this.uidPengunggah,
    required this.date,
  });

  @override
  State<PostinganHangatCard> createState() => _PostinganHangatCardState();
}

class _PostinganHangatCardState extends State<PostinganHangatCard> {
  String authorName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAuthorName();
  }

  Future<void> _fetchAuthorName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uidPengunggah)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          authorName = data?['nama'] ?? 'Unknown';
          isLoading = false;
        });
      } else {
        setState(() {
          authorName = 'Unknown';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        authorName = 'Unknown';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================================
          // IMAGE (placeholder base_thumbnail)
          // ================================
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: widget.img,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,

              // placeholder pakai base_thumbnail
              placeholder: (context, url) => Image.asset(
                "assets/images/base_thumbnail.png",
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              // errorWidget
              errorWidget: (context, url, error) => Image.asset(
                "assets/images/base_thumbnail.png",
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // TITLE
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: semibold.copyWith(fontSize: 14),
          ),

          const SizedBox(height: 8),

          // PROFIL + INFO
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CachedNetworkImage(
                  imageUrl:
                      "https://i.pinimg.com/564x/47/ab/e9/47abe90aaea457e9157cc019ccfeb439.jpg",
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,

                  // Foto profil placeholder
                  placeholder: (context, url) => Image.asset(
                    "assets/images/photo_profile.png",
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),

                  // errorWidget pakai placeholder
                  errorWidget: (context, url, error) => Image.asset(
                    "assets/images/photo_profile.png",
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AUTHOR NAME
                    isLoading
                        ? Container(
                            width: 60,
                            height: 10,
                            color: Colors.grey[300],
                          )
                        : Text(
                            authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: semibold.copyWith(
                              fontSize: 11,
                              color: textPrimary,
                            ),
                          ),
                    const SizedBox(height: 2),
                    // DATE
                    Text(
                      widget.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: regular.copyWith(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
