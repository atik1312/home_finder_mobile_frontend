import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:home_finder_/auth/api_service.dart';
import 'package:home_finder_/models/user.dart';
import 'package:home_finder_/pages/login.dart';

class SignUp extends StatefulWidget {
  static const String routeName = "/signup";
  SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  double height=0;
  final _formKey = GlobalKey<FormState>();
  final _nameController=TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repasswordController = TextEditingController();
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1),(){
      setState(() {
        height=MediaQuery.of(context).size.height*0.8;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
   final size=MediaQuery.of(context).size;
    
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color.fromARGB(255, 239, 235, 247),const Color.fromARGB(255, 211, 202, 245)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight
              )
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children:[
                  SizedBox(height: size.height*0.05,),
                 AnimatedContainer(
                  height: height,
                  duration: Duration(seconds: 2),
                   child: SingleChildScrollView(
                     child: Container(
                          width: double.infinity,
                          // height: height,
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color.fromARGB(255, 255, 255, 255),const Color.fromARGB(255, 255, 255, 255)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight
                            ),
                            borderRadius: BorderRadius.circular(20.0)
                          ),
                          child: Form(
                            key: _formKey,
                            child:Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Create an Account",style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
                                SizedBox(height: 16.0,),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType:TextInputType.emailAddress ,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.email),
                                      hintText: "Email Address",
                                      filled: true,
                                      fillColor: const Color.fromARGB(255, 235, 245, 192),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(8.0)
                                      )
                                    ),
                                    validator: (value) {
                                      if(value==null|| value.isEmpty){
                                        return 'Provide a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 8.0,),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.person),
                                      hintText: "Name",
                                      filled: true,
                                      fillColor: const Color.fromARGB(255, 235, 245, 192),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(8.0)
                                      )
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.0,),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType:TextInputType.phone ,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.phone),
                                      hintText: "Phone Number",
                                      filled: true,
                                      fillColor: const Color.fromARGB(255, 235, 245, 192),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(8.0)
                                      )
                                    ),
                                    validator: (value) {
                                      if(value==null|| value.isEmpty){
                                        return "Provide a valid Phone number";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 8.0,),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: TextFormField(
                                    obscureText: true,
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      prefixIcon: const Icon(Icons.password),
                                      hintText: "Password (atleast 6 characters)",
                                       fillColor: const Color.fromARGB(255, 235, 245, 192),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(8.0)
                                      )
                                    ),
                                    validator: (value) {
                                      if(value==null|| value.isEmpty||value.length<6){
                                        return 'Provide a valid password';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 8.0,),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: TextFormField(
                                    obscureText: true,
                                    controller: _repasswordController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      prefixIcon: const Icon(Icons.password),
                                      hintText: "Confirm Password (same as pasword)",
                                       fillColor: const Color.fromARGB(255, 235, 245, 192),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(8.0)
                                      )
                                    ),
                                    validator: (value) {
                                      if(value==null|| value.isEmpty||_passwordController.text!=_repasswordController.text){
                                        return 'must same  as  password';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 8.0,),
                                Padding(padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.25),
                                child: ElevatedButton(onPressed:_signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 243, 247, 198),
                                    foregroundColor: Colors.black,  
                                    elevation: 10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0)
                                    )
                                  ),
                                  child: Text("Sign Up")),
                                ),
                                SizedBox(height: 8.0,),
                                
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: "Already have an account? ",
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "Login",
                                        style: TextStyle(color: Colors.blue,fontWeight: FontWeight.bold),
                                        recognizer: TapGestureRecognizer()..onTap=(){
                                          context.goNamed(LoginPage.routeName);
                                        }
                                      )
                                    ]
                                  )
                                ),
                               
                                
                              ],
                            )
                            ),
                        
                      ),
                   ),
                 ),
                  
                  ]
                ),
              ),
            )
          ),
        ),
      ),
    );
 
  }

  void _signUp() async{

    EasyLoading.show(status: "Signing up...");
    if(_formKey.currentState!.validate()){
      final user=User(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
      );
      await ApiService.signUp(user, _passwordController.text).then((result){
        if(result==true){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign up successful! Please login.")));
          context.goNamed(LoginPage.routeName);
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email already exists! Or network is not stable.")));
        }
      });
    }
    EasyLoading.dismiss();
  }
}