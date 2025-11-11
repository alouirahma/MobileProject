import 'package:flutter/material.dart';
import 'text_field_container.dart'; // ← CORRIGÉ : chemin local
import '../constants.dart';

class RoundedNameField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? vaildator; // ← GARDÉ "vaildator"
  final TextEditingController? textEditingController;

  const RoundedNameField({
    super.key, // ← CORRIGÉ
    required this.hintText,
    this.icon = Icons.person,
    this.onChanged,
    this.vaildator,
    this.textEditingController,
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.name,
        controller: textEditingController,
        validator: vaildator,
        onChanged: onChanged,
        cursorColor: kPrimaryColor,
        decoration: InputDecoration(
          icon: Icon(icon, color: kPrimaryColor),
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
