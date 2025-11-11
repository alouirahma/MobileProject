import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile2025/Entites/User.dart';
import 'package:mobile2025/Services/database_helper.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  RegisterBloc() : super(RegisterInitial()) {
    on<RegisterSubmitEvent>(_onSubmit);
  }

  Future<void> _onSubmit(
    RegisterSubmitEvent event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());

    final user = await dbHelper.registerUser(
      username: event.username,
      name: event.name,
      email: event.email,
      password: event.password,
      avatar: event.avatar,
    );

    if (user == null) {
      emit(RegisterFailure(error: 'Username ou email déjà utilisé'));
    } else {
      emit(RegisterSuccess(user: user));
    }
  }
}
