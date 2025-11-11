// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/bloc/authentication/authentication_bloc.dart';
import 'package:mobile2025/bloc/register/register_bloc.dart';
import 'package:mobile2025/screens/welcome/welcome_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database; // Initialise la base
  await initializeDateFormatting('fr_FR', null); // Pour "06 nov."
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RegisterBloc()),
        BlocProvider(create: (_) => AuthenticationBloc()),
      ],
      child: MaterialApp(
        title: 'Mobile2025',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const WelcomeScreen(),
      ),
    );
  }
}
