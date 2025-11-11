import 'package:flutter/material.dart';
import '../constants.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback press; // ← CORRIGÉ : VoidCallback (pas Function)
  final Color color, textColor; // ← GARDÉ EXACTEMENT

  const RoundedButton({
    super.key, // ← CORRIGÉ : super.key
    required this.text, // ← required car non-nullable
    required this.press, // ← required
    this.color = kPrimaryColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: size.width * 0.8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            backgroundColor: color,
          ),
          onPressed: press, // ← maintenant OK
          child: Text(text, style: TextStyle(color: textColor)),
        ),
      ),
    );
  }
}
