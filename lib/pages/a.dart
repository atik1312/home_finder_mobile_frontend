
void main(){
 String ? name = "Flutter";
 printLength(name: name);

}


void printLength({String? name}){
  if(name==null){
    return;
  }
  print(name.length);
}