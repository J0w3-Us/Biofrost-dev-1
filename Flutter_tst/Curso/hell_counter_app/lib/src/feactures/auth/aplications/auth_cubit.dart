import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    emit(AuthLoading());

    await Future.delayed(const Duration(seconds: 2));

    if (email == "test@gmail.com" && password == "12345") {
      emit(Authenticated());
    } else {
      emit(AuthFailure("Deneged Credencial. Please, try again latter"));
    }
  }

  void logout() {
    emit(Unauthenticated());
  }
}
