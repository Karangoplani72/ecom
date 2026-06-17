import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage:
      imageUrl != null
          ? NetworkImage(imageUrl!)
          : null,
      child:
      imageUrl == null
          ? const Icon(Icons.person)
          : null,
    );
  }
}