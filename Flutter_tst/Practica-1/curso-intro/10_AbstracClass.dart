void main (){

  final windPlant = WindPlant( iniEnergy: 100);
  final nuclearEnergy = NuclearEnergy ( energyLeft: 1000);
  
  
  print('wind: ${ chargePone (windPlant) }');
  print('nuclear: ${ chargePone (nuclearEnergy) }');
}

// ejemplo con carga de telefono

double chargePone( EnergyPlan plant){
  if (plant.energyLeft < 10 ){
    throw Exception ('not found charge');
  }
  return plant.energyLeft - 10; 
}

// clase abstracta
enum PlantType{ nuclear, water, wind }

abstract class EnergyPlan{
  
  double energyLeft;
  final PlantType type;
  
  EnergyPlan({
    required this.energyLeft,
    required this.type
            });
 
  void consumeEnerrgy (double amount);
//   void consumeEnergy (double amount)
//   trhow UniPlementError();
  
}


// extenxs o implementos 
// Los extenxs so aquellos que heredan otras clases 
class WindPlant extends EnergyPlan{
  WindPlant({ required double iniEnergy })
    : super( energyLeft: iniEnergy, type: PlantType.wind );
  
  
  @override
  void consumeEnerrgy( double amount ){
    energyLeft -= amount;
  }
}


class NuclearEnergy implements EnergyPlan {
  
  @override
  double energyLeft;

  @override
  final PlantType type = PlantType.nuclear;
  NuclearEnergy ({ required this.energyLeft }); 
  
   @override
  void consumeEnerrgy( double amount ){
    energyLeft -= amount;
  } 
}