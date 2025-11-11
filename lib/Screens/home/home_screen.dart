import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile2025/Screens/stats_screen.dart';
import 'package:mobile2025/constants.dart';
import 'package:mobile2025/Entites/User.dart';
import 'package:mobile2025/bloc/authentication/authentication_bloc.dart';
import 'package:mobile2025/components/rounded_button.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String str = '';

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationLogOutState) {
          Navigator.popUntil(context, ModalRoute.withName('/'));
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),

              // 🟢 PHOTO DE PROFIL (avatar)
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[200],
                backgroundImage: widget.user.avatar != null
                    ? AssetImage(widget.user.avatar!)
                    : const AssetImage("lib/assets/images/default_avatar.png"),
              ),

              const SizedBox(height: 20),

              // 🟢 TEXTE HELLO
              const Text(
                'Hello',
                style: TextStyle(
                  fontSize: 80.0,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),

              // 🟢 NOM UTILISATEUR
              Text(
                '${widget.user.name},',
                style: const TextStyle(
                  fontSize: 50.0,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 50),
              // 🟢 Mon PROFILE
              const SizedBox(height: 50),

              // 🟣 BOUTON MON PROFIL
              RoundedButton(
                text: "MON PROFIL",
                color: Colors.deepPurple,
                textColor: Colors.white,
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatsScreen(user: widget.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              Text(str, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // 🟢 BOUTON LOGOUT
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.read<AuthenticationBloc>().add(AuthenticationLogOutEvent());
          },
          label: const Text('Log Out'),
        ),
      ),
    );
  }
}
