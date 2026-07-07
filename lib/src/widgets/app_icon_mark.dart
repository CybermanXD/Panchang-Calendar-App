import 'package:flutter/widgets.dart';

class AppIconMark extends StatelessWidget {
  const AppIconMark({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/app-icon.png', width: size, height: size, fit: BoxFit.contain);
  }
}
