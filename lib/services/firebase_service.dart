import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error during sign up: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  // Send a command to Firebase Realtime Database
  void sendCommand(String command) {
    _database.ref('commands').set({
      'command': command,
      'timestamp': DateTime.now().toString(),
    });
  }

  // Listen for commands from Firebase Realtime Database
  Stream<Map<dynamic, dynamic>> listenForCommands() {
    return _database.ref('commands').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data ?? {};
    });
  }
}