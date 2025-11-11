import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile2025/Entites/User.dart';
import 'package:mobile2025/Services/database_helper.dart';
part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final dbHelper = DatabaseHelper();

  AuthenticationBloc() : super(AuthenticationInitial()) {
    on<AuthenticationSubmitEvent>(_onSubmit);
    on<AuthenticationLogOutEvent>(_onLogOut);
  }

  Future<void> _onSubmit(
    AuthenticationSubmitEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoadingState());

    // Utilise la méthode que tu as dans DatabaseHelper
    final user = await dbHelper.signInByUsername(
      event.username,
      event.password,
    );

    if (user == null) {
      emit(AuthenticationFailState());
    } else {
      emit(AuthenticationSuccessState(user: user));
    }
  }

  void _onLogOut(
    AuthenticationLogOutEvent event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(AuthenticationLogOutState());
  }
}
