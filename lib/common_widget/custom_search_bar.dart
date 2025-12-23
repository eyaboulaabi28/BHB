import 'package:flutter/material.dart';

/// Une barre de recherche réutilisable, moderne et stylée
class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final String hintText;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onFilterTap,
    this.hintText = 'ابحث...',
    this.margin,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.grey,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: onFilterTap != null
                ? IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.grey),
              onPressed: onFilterTap,
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
