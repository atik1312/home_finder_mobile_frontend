import 'dart:async';
import 'dart:developer';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:home_finder_/auth/api_service.dart';
import 'package:home_finder_/auth/loggedUser.dart';
import 'package:home_finder_/pages/home_page.dart';
import 'package:home_finder_/pages/sign_up.dart';

import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const String routeName="/login";
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin{
  bool _isSecured=true;
  late AnimationController _controller;
  late Animation<Offset> _animation;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _timer; // Store the Timer instance
  var _textOpacity = 0.0;
  String _errMsg = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose(); // Dispose the animation controller
    _timer?.cancel(); // Cancel the timer
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, 2), // Start off-screen (below)
      end: Offset.zero, // End at the original position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _timer = Timer.periodic(Duration(milliseconds: 2000), (none) {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _textOpacity = _textOpacity == 0.0 ? 1.0 : 0.0;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final size=MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      child: Scaffold(
        // resizeToAvoidBottomInset: false,
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color.fromARGB(255, 239, 235, 247),const Color.fromARGB(255, 211, 202, 245)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
            )
          ),
          child: SingleChildScrollView(
            child: Column(
              children:[
              SizedBox(height: size.height*0.05,),
              Lottie.asset("assets/loginLogo.json",width: size.width*0.7,height: size.height*0.35,
              repeat: true
              ),
              AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _textOpacity,
                child: Text("Home Finder!",style: TextStyle(fontSize: 35,fontWeight: FontWeight.bold,color: Colors.black),)),
              SizedBox(height: size.height*0.01,),
              SlideTransition(
                position: _animation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    gradient: LinearGradient(
                      colors: [const Color.fromARGB(255, 255, 255, 255),const Color.fromARGB(255, 255, 255, 255)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight
                    ),
                    borderRadius: BorderRadius.circular(20.0)
                  ),
                  child: Form(
                    key: _formKey,
                    child:ListView(
                      padding: const EdgeInsets.all(10.0),
                      shrinkWrap: true,
                      children: [
                     
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
                            obscureText: _isSecured,
                            controller: _passwordController,
                            decoration: InputDecoration(
                              filled: true,
                              prefixIcon: const Icon(Icons.password),
                              suffixIcon: IconButton(onPressed: (){
                                setState(() {
                                  _isSecured=!_isSecured;
                                });
                              }, icon: Icon(_isSecured?Icons.visibility:Icons.visibility_off)),
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
                        Padding(padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.25),
                        child: ElevatedButton(onPressed:_authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 243, 247, 198),
                            foregroundColor: Colors.black,  
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)
                            )
                          ),
                          child: Text("Login")),
                        ),
                        SizedBox(height: 8.0,),
                        
                        SizedBox(height: 8.0,),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: "Sign Up",
                                style: TextStyle(color: Colors.blue,fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()..onTap=(){
                                  context.goNamed(SignUp.routeName);
                                }
                              )
                            ]
                          )
                        ),
                        _errMsg.isNotEmpty? Text(_errMsg,style: TextStyle(fontSize: 18,color: Colors.red),):SizedBox.shrink()
                        
                      ],
                    )
                    ),
                ),
              ),
              ]
            ),
          )
        ),
      ),
    );
 
  }

  void _authenticate() async{
    if(_formKey.currentState!.validate()){
      EasyLoading.show(status: "Please Wait");
      final email=_emailController.text;
      final password=_passwordController.text;
      try{
        final user=await ApiService.logIn(email, password);
        log(user.toString());
        await LoggedUser.instance.setUser(user);
        EasyLoading.dismiss();
        context.goNamed(HomePage.routeName);
      } catch(error){
        EasyLoading.dismiss();
        log(error.toString());
        setState(() {
          _errMsg=error.toString();
        });
      }
    }
    
  }
}