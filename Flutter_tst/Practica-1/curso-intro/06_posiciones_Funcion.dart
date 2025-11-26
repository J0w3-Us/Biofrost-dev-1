void main() {
  
  print(greetEveryone());
  
  print('suma ${addTwoNumbers(12,44)}');
  
  print(greetPerson(name: 'jose'));
  
  
}

String  greetEveryone() =>'hello everyone';

int addTwoNumbers(int a, int b) => a + b;


//registro opcional

//int addTwonuymbersOpcional(int a, [int? b]) {
  //b ??= 0;
  //return a + b;
//}

int addTwoNumbersOpcional(int a, [int b = 0]){
  return a + b;
}


//valoresd posicionales
String greetPerson({required String name, String? message = 'Holas'}) {
  return '$message jose';
}