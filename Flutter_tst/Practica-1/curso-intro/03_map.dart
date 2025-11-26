void main() {
  final String name = 'jose';
  final int edad = 19;
  final bool isLive = true;

 //map
  final Map<String, dynamic> persona = {
    'name': name,
    'edad': edad,
    'isLive': isLive,
    'Habilities': ['Dart', 'Flutter', 'Python'],

    'Sprits': {1: 'rojo/Front.jpg', 2: 'rojo/Back.jpg'},
  };

  print(persona);
  print('name: ${persona['name']}');
  print('edad: ${persona['edad']}');

  print('Back ${persona['Sprits'][2]}');
  print('Front ${persona['Sprits'][1]}');
}
