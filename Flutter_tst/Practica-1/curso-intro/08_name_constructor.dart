void main() {
  
//   peticion web
  final Map<String, dynamic>peticion = {
    'name': 'Peter Parker',
    'power': 'Sentido aracnido',
    'isLive': false
  };
  
  final hulk = Heroe.pool(peticion);
  
//   final hulk = Heroe(
//     isLive: true,
//     power: 'intelicen',
//     name: 'bruce barner'
//   );
  
  print( hulk );
  
}

class Heroe{
  String name;
  String power;
  bool isLive;
  
  
  Heroe({
    required this.name,
    required this.power,
    required this.isLive
  });
//   constructor con nombre
  Heroe.pool(Map<String, dynamic> json) 
    : name = json['name'] ?? 'not name found',
      power = json['power'] ?? 'not found power',
      isLive = json['isLive'] ?? 'Not found live';
  
  @override
  String toString(){
//     ternario "${is live ? Yes : Nope}"
    return '$name, $power, ${isLive ? 'Yes': 'Nope'}';
  }
}