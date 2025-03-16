import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'database/firebase_options.dart';  // Import your generated firebase_options.dart
import 'login_screen.dart';
import 'income_screen.dart';  // Import the new income screen
import 'profile_screen.dart';  // Import the profile screen
import 'transaction_screen.dart';  // Import the transaction screen
import 'home_screen.dart';  // Import the home screen
import 'summary_screen.dart';  // Import the summary screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Ensure correct FirebaseOptions
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      routes: {
        '/home': (context) => HomeScreen(),  // Add route for home screen
        '/income': (context) => IncomeScreen(),  // Add route for income screen
        '/profile': (context) => ProfileScreen(),  // Add route for profile screen
        '/transactions': (context) => TransactionScreen(),  // Add route for transaction screen
        '/summary': (context) => SummaryScreen(),  // Add route for summary screen
      },
    );
  }
}
