void main (){

print ('Programa iniciado');

httpGet('http//:jose+is+god.com ').then( (value) {
  print (value);
}).catchError( (err) {
  print('Error: $err');
});


print ('Programa finalizado');

}

Future <String> httpGet (String url){
return Future.delayed( Duration(seconds: 2), () {
  
  throw 'http no fue realizada correctamnete';
//     return 'exeption realizada, por el http del cliente';
});
}