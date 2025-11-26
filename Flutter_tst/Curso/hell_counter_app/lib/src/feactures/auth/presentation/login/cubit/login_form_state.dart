part of 'login_form_cubit.dart';

class LoginFormState {
  final bool isRememberMeChecked;

  const LoginFormState({this.isRememberMeChecked = false});

  LoginFormState copyWith({bool? isRememberMeChecked}) {
    return LoginFormState(
      isRememberMeChecked: isRememberMeChecked ?? this.isRememberMeChecked,
    );
  }
}
