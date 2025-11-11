import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ← AJOUTÉ
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile2025/Screens/login/login_screen.dart';
import 'package:mobile2025/Screens/register/components/or_divider.dart';
import 'package:mobile2025/Screens/register/components/social_icon.dart';
import 'package:mobile2025/bloc/register/register_bloc.dart';
import 'package:mobile2025/components/already_have_account.dart';
import 'package:mobile2025/components/rounded_button.dart';
import 'package:mobile2025/components/rounded_input_field.dart';
import 'package:mobile2025/components/rounded_name_field.dart';
import 'package:mobile2025/components/rounded_password_field.dart';
import 'background.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // ← +
  String? _selectedAvatar;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Background(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                "SIGNUP",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: size.height * 0.03),
              SvgPicture.asset(
                "lib/assets/icons/signup.svg",
                height: size.height * 0.25,
              ),
              //+
              SizedBox(height: size.height * 0.03),

              // === CHOISIR PARMI 2 AVATARS OU AUCUN ===
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: AssetImage(
                                    "lib/assets/images/avatar2.png",
                                  ),
                                ),
                                title: const Text("Avatar 1"),
                                onTap: () {
                                  setState(
                                    () => _selectedAvatar =
                                        "lib/assets/images/avatar2.png",
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: AssetImage(
                                    "lib/assets/images/avatar3.jpg",
                                  ),
                                ),
                                title: const Text("Avatar 2"),
                                onTap: () {
                                  setState(
                                    () => _selectedAvatar =
                                        "lib/assets/images/avatar3.jpg",
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.person_off),
                                title: const Text("Aucune photo"),
                                onTap: () {
                                  setState(() => _selectedAvatar = null);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedAvatar != null
                            ? AssetImage(_selectedAvatar!)
                            : null,
                        child: _selectedAvatar == null
                            ? const Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedAvatar == null
                          ? "Tap to choose avatar"
                          : "Avatar selected",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.03),

              // NAME FIELD
              RoundedNameField(
                hintText: "Your Name",
                textEditingController: nameController,
                vaildator: (value) {
                  if (value == null || value.length < 4) {
                    return 'Name should be more than 4 characters';
                  }
                  return null;
                },
                onChanged: (value) {},
              ),

              // USERNAME FIELD
              RoundedInputField(
                key: const ValueKey('username_field'),
                hintText: "Username",
                icon: Icons.person,
                textEditingController: usernameController,
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'Username should be more than 4 characters';
                  }
                  return null;
                },
                onChanged: (value) {},
              ),

              // PASSWORD FIELD
              RoundedPasswordField(
                key: const ValueKey('password_field'),
                textEditingController: passwordController,
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'Password should be more than 4 characters';
                  }
                  return null;
                },
                onChanged: (value) {},
              ),

              // BUTTON
              RoundedButton(
                text: "SIGNUP",
                press: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    context.read<RegisterBloc>().add(
                      RegisterSubmitEvent(
                        name: nameController.text,
                        username: usernameController.text,
                        email: '', // TEMPORAIRE
                        password: passwordController.text,
                        avatar: _selectedAvatar,
                      ),
                    );
                  }
                },
              ),

              SizedBox(height: size.height * 0.03),
              AlreadyHaveAnAccountCheck(
                login: false,
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),

              // CORRIGÉ : PAS const
              OrDivider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SocalIcon(
                    iconSrc: "lib/assets/icons/facebook.svg",
                    press: () {},
                  ),
                  SocalIcon(
                    iconSrc: "lib/assets/icons/twitter.svg",
                    press: () {},
                  ),
                  SocalIcon(
                    iconSrc: "lib/assets/icons/google-plus.svg",
                    press: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
