import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_list/pages/auth/register_page.dart';
import 'package:grocery_list/pages/home_page.dart';
import 'package:grocery_list/services/auth_service.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30), // Placeholder for spacing, adjust as needed
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0), // Add padding around the icon
                child: Icon(
                  Icons.shopping_cart_checkout_rounded,
                  size: 100, // Adjust the size of the icon
                ),
              ),
            ),
            const Text('Email'),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email),
                hintText: 'Enter your email',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Password'),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock),
                hintText: 'Enter your password',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Register",
                    style: TextStyle(
                      color: Colors.blue, // Customize the text color
                      decoration: TextDecoration.underline, // Underline the text
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        User? user = await logIn(emailController.text, passwordController.text);
                        if (user != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage(user: user)),
                          );
                        } else {
                          // Handle login error, show a snackbar or dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Login failed. Please check your credentials.')),
                          );
                        }
                      } catch (e) {
                        // Handle login errors
                        print('Error logging in: $e');
                        // Show error message to the user
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error logging in: $e')),
                        );
                      }
                    },
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<User?> logIn(String email, String password) async {
    final auth = FirebaseAuth.instance;

    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print('Error logging in: $e');
    }
    return null;
  }

  String hashPassword(String password) {
    // Use SHA-256 hashing algorithm
    final bytes = utf8.encode(password); // Encode password as UTF-8
    final hashedBytes = sha256.convert(bytes).bytes; // Hash the bytes
    return base64Encode(hashedBytes); // Encode hashed bytes as base64 string
  }
}
