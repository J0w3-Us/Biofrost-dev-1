import 'package:flutter_bloc/flutter_bloc.dart';

part 'login_form_state.dart';

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(const LoginFormState());

  void toggleRememberMe(bool newValue) {
    emit(state.copyWith(isRememberMeChecked: newValue));
  }
}
