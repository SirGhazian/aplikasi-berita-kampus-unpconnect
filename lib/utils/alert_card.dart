import 'package:flutter/material.dart';
import '../theme.dart';

class AlertCard extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String cancelText;
  final String confirmText;

  const AlertCard({
    super.key,
    required this.title,
    required this.content,
    required this.onCancel,
    required this.onConfirm,
    this.cancelText = "BATAL",
    this.confirmText = "HAPUS",
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Merah
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: dangerColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: semibold.copyWith(fontSize: 18, color: Colors.white),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: medium.copyWith(fontSize: 16, color: Colors.black),
            ),
          ),

          // Tombol
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cancelText,
                        style: semibold.copyWith(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: dangerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        confirmText,
                        style: semibold.copyWith(
                          fontSize: 14,
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
      ),
    );
  }
}
