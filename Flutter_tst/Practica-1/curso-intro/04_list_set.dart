void main() {
  final numbers = [1, 1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 7, 7];

  print('list: $numbers');
  print('length: ${numbers.length}');
  print('Index number: ${numbers[0]}');
  //comando first
  print('first number: ${numbers.first}');
  //numeros al reves
  print('reverse: ${numbers.reversed}');
  
  
  //iterables
  final recverNumber = numbers.reversed;
  print('iterable: ${recverNumber}');
  //listado
  print('list: ${recverNumber.toList()}');
  //set
  print('set: ${recverNumber.toSet()}');
  
  //numerGreaterThat5
  final numberGreaterThat5 = numbers.where ( (num){
    return num > 5;
  });
  
  //interable
  print('numbergreat 5: ${numberGreaterThat5}');
  
  //set de datos
  print('nuumberset: ${numberGreaterThat5.toSet()}');
}
