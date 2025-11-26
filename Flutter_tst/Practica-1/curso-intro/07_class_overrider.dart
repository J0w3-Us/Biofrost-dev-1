void main(){
  
  final Heroe wolwerine = Heroe (name:'logan', power:'garras');
  
  print(wolwerine);
  print(wolwerine.name);
  print(wolwerine.power);
}


class Heroe{
  String name;
  String power;
  
//   Heroe(this.name, this.power);
  
//   Heroe ( String pName, String pPower)
    
//   : name = pName,
//     power = pPower;
  
  Heroe({
    required this.name,
    this.power = 'sin power'
  });
  
  @override
  String toString(){
    return '$name - $power';
  }
  }