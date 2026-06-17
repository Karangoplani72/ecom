import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: 'Search products...',
      leading: const Icon(Icons.search),
      onChanged: onChanged,
    );
  }
}