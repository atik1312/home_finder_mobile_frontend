
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_finder_/auth/loggedUser.dart';
import 'package:home_finder_/models/user.dart';
import 'package:home_finder_/pages/create_post.dart';
import 'package:home_finder_/pages/home_page.dart';
import 'package:home_finder_/pages/login.dart';
import 'package:home_finder_/pages/sign_up.dart';
import 'package:home_finder_/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  Hive.registerAdapter(UserAdapter());

  await LoggedUser.instance.loadUser();
  if (LoggedUser.instance.user != null) {
  log('User is logged in: ${LoggedUser.instance.user}');
} else {
  log('No user is logged in.');
}
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  final _router = GoRouter(
  initialLocation: SplashScreen.routeName,
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final loggedIn = LoggedUser.instance.user != null;

    final authPages = [
      SplashScreen.routeName,
      LoginPage.routeName,
      SignUp.routeName
    ];

    final isAuthPage = authPages.contains(state.uri.path);

    if (!loggedIn && !isAuthPage) {
      return LoginPage.routeName;
    }

    if (loggedIn && isAuthPage) {
      return HomePage.routeName;
    }

    return null;
  },
  routes: [
    GoRoute(
      name: SplashScreen.routeName,
      path: SplashScreen.routeName,
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      name: LoginPage.routeName,
      path: LoginPage.routeName,
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      name: SignUp.routeName,
      path: SignUp.routeName,
      builder: (context, state) => SignUp(),
    ),
    GoRoute(
      name: HomePage.routeName,
      path: HomePage.routeName,
      builder: (context, state) =>
          HomePage(user: LoggedUser.instance.user!),
    ),
    GoRoute(
      name: CreatePost.routeName,
      path: CreatePost.routeName,
      builder: (context, state) => const CreatePost(),
    ),
  ],
);
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      builder:  EasyLoading.init(),
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        
      ),
      routerConfig: _router,
    );
  }
}