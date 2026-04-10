import 'package:hive/hive.dart';
import 'package:home_finder_/models/user.dart';

class LoggedUser {
  // Private constructor
  LoggedUser._privateConstructor();

  // The single instance of the class
  static final LoggedUser _instance = LoggedUser._privateConstructor();

  // Getter to access the single instance
  static LoggedUser get instance => _instance;

  // The logged-in user data
  User? user;

  // Method to set the user data and store it in Hive
  Future<void> setUser(User loggedInUser) async {
    user = loggedInUser;
    final box = await Hive.openBox<User>('loggedUserBox');
    await box.put('user', loggedInUser);             
  }

  // Method to retrieve the user data from Hive
  Future<void> loadUser() async {
    final box = await Hive.openBox<User>('loggedUserBox');
    user = box.get('user');
  }

  // Method to clear the user data (e.g., on logout)
  Future<void> clearUser() async {
    user = null;
    final box = await Hive.openBox<User>('loggedUserBox');
    await box.delete('user');
  }
}