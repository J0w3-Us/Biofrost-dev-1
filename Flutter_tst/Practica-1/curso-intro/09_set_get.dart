void main() {
  
  final mySquered = Squered(side: -10);
  
//   mySquered.side = -6;
  
  print('area: ${mySquered.area}');
}

class Squered{
  
  double _side; //lado * lado
 
    
    Squered({required double side})
      : assert(side >= 0, 'El lado debe de ser mayor a 0'),
        _side = side;
    
    double get area{
      return _side * _side;
    }
    
    set side(double value) {
      print('setting new value: $value');
      
      if(value < 0) throw 'Value must be greater than 0';
      
      _side = value;
    } 
  
  double calcularArea(){
    return _side * _side;
  }
}