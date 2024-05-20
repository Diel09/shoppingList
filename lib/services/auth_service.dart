import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  //read
  Future<void> registerUser(String email, String password, String name, String location) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add additional user information to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'userId': userCredential.user?.uid,
        'name': name,
        'email': email,
        'location': location,
      });

      // Successfully registered
      print('Registration successful: ${userCredential.user?.email}');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print('Error registering: $e');
    }
  }
  
  //delete
  void deleteList(String docId) async {
    await users.doc(docId).delete();
  }
}
