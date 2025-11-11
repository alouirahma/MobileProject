import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants.dart';

class SocalIcon extends StatelessWidget {
  final String iconSrc;
  final VoidCallback? press; // ← Function remplacé par VoidCallback?
  const SocalIcon({
    super.key, // ← Remplace Key key
    required this.iconSrc, // ← Obligatoire car nécessaire pour l’affichage
    this.press, // ← Optionnel
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: kPrimaryLightColor),
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(iconSrc, height: 20, width: 20),
      ),
    );
  }
}
