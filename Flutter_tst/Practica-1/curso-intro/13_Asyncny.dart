void main() {
  
  emitNumber()
    .listen( (value) { 
    print('stream listen: $value');
    });
}


Stream emitNumber() async*{
  final valuesToEmit = [1,2,3,4];
  
  for (int i in valuesToEmit) {
    await Future.delayed(const Duration(seconds: 1));
    
    yield i; 
  }
  }