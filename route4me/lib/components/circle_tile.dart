import 'package:flutter/material.dart';

class CircleTile extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
  const CircleTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          shape: BoxShape.circle, // Use BoxShape.circle to make it circular
          color: Colors.grey[200],
        ),
        child: CircleAvatar(
          backgroundImage: AssetImage(imagePath),
          radius: 20, // Set the radius as needed
        ),
      ),
    );
  }
}
