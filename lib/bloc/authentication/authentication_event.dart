// lib/bloc/authentication/authentication_event.dart
part of 'authentication_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();
  @override
  List<Object?> get props => [];
}

class AuthenticationSubmitEvent extends AuthenticationEvent {
  final String username;
  final String password;

  const AuthenticationSubmitEvent({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class AuthenticationLogOutEvent extends AuthenticationEvent {}
