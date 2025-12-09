import 'package:flutter/material.dart';
import '../theme.dart';

class SearchFieldWithHeader extends StatelessWidget {
  final String? title; // opsional
  final Widget? titleWidget; // opsional
  final TextEditingController controller;
  final Function(String)? onChanged;

  const SearchFieldWithHeader({
    super.key,
    this.title,
    this.titleWidget,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER PUTIH
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          color: secondaryColor,
          child: titleWidget ?? Text(title ?? "", style: large),
        ),

        const SizedBox(height: 20),

        // SEARCH BAR
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
                      controller: controller,
                      onChanged: onChanged,
                      style: regular.copyWith(color: textPrimary),
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
      ],
    );
  }
}
