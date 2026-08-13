import 'package:flutter/material.dart';

class FoldClipper extends CustomClipper<Path> {
  const FoldClipper({this.notchSize = 16, this.cornerRadius = 14});
  final double notchSize;
  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final r = cornerRadius;
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(notchSize, size.height)
      ..lineTo(0, size.height - notchSize)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}