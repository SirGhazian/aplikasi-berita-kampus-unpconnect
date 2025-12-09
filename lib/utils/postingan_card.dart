import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class PostinganCard extends StatefulWidget {
  final String title;
  final String? tag;
  final String? uidPengunggah;
  final String date;
  final String image;
  final VoidCallback? onTap;

  const PostinganCard({
    super.key,
    required this.title,
    this.tag,
    this.uidPengunggah,
    required this.date,
    required this.image,
    this.onTap,
    this.margin,
    this.borderRadius,
  });

  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;

  @override
  State<PostinganCard> createState() => _PostinganCardState();
}

class _PostinganCardState extends State<PostinganCard> {
  String displayText = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDisplayText();
  }

  Future<void> _fetchDisplayText() async {
    // jika tag ada (kampus post)
    if (widget.tag != null) {
      setState(() {
        displayText = widget.tag!;
        isLoading = false;
      });
      return;
    }

    // jika tidak, fetch author name (mahasiswa post)
    if (widget.uidPengunggah != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uidPengunggah)
            .get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            displayText = data?['nama'] ?? 'Unknown';
            isLoading = false;
          });
        } else {
          setState(() {
            displayText = 'Unknown';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          displayText = 'Unknown';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        displayText = 'Unknown';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // ===========================
            // Thumbnail (Cached Image)
            // ===========================
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.image,
                width: 90,
                height: 90,
                fit: BoxFit.cover,

                // placeholder pakai base_thumbnail
                placeholder: (context, url) => Image.asset(
                  "assets/images/base_thumbnail.png",
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),

                // errorWidget DIHAPUS > fallback tetap placeholder
                errorWidget: (context, url, error) => Image.asset(
                  "assets/images/base_thumbnail.png",
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ===========================
            // Teks konten
            // ===========================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  isLoading
                      ? SizedBox(
                          width: 40,
                          height: 10,
                          child: Container(color: Colors.grey[300]),
                        )
                      : Text(
                          displayText,
                          style: semibold.copyWith(
                            fontSize: 10,
                            color: primaryColor,
                          ),
                        ),

                  const SizedBox(height: 8),

                  // Judul
                  Text(
                    widget.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: semibold.copyWith(fontSize: 14, color: textPrimary),
                  ),

                  const SizedBox(height: 4),

                  // Tanggal
                  Text(
                    widget.date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: regular.copyWith(fontSize: 10, color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
