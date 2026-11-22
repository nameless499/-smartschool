import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../utils/breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (context) => mobile,
      tablet: (context) => tablet,
      desktop: (context) => desktop,
    );
  }
}
