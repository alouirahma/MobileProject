part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
  @override
  List<Object?> get props => [];
}

class RegisterSubmitEvent extends RegisterEvent {
  final String name;
  final String username;
  final String email;
  final String password;
  final String? avatar;

  const RegisterSubmitEvent({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    this.avatar, // AJOUTÉ
  });

  @override
  List<Object?> get props => [name, username, email, password, avatar];
}
