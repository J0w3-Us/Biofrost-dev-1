class Animal{}

abstract class Manifero extends Animal {}
abstract class Ave extends Animal {}
abstract class Pez extends Animal {}

mixin Caminante {
  void caminar() => print('Estoy caminando ');
}

mixin Volador {
  void volador() => print('Estoy volando');
}

mixin Nadador {
  void nadador() => print('Estoy nadando');
}

class Delfin extends Manifero with Nadador {}
class Murcielago extends Manifero with Volador, Caminante {}
class Gato extends Manifero with Caminante {}

class Tiburon extends Pez with Nadador {}
class PezVolador extends Pez with Nadador, Volador {}

class Pato extends Ave with Nadador, Volador, Caminante {}
class Paloma extends Ave with Volador, Caminante {}

void main () {
  final susy = Delfin();
  susy.nadador();
}