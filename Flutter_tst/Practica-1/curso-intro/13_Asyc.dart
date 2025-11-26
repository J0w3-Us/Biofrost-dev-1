void main () async{
  
  print ('Programa iniciado');
  
  
  try{
    final value = await httpGet('http//:jose+is+god.com ');
    print (value); 
  }
 catch (err){
  print('tenemos un error $err');
 }
  
  
  print ('Programa finalizado');
 
}

Future <String> httpGet (String url) async{
  await Future.delayed( Duration(seconds: 2), () {
    
    throw 'http no fue realizada correctamnete';
//     return 'exeption realizada, por el http del cliente';
  });
 }
