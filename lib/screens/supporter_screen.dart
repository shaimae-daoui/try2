import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart'; // Ensure this import is correct
import '../services/firebase_service.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String _lastCommand = 'No command received';
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _listenForCommands(); // Start listening for commands when the screen loads
  }

  void _listenForCommands() {
    _firebaseService.listenForCommands().listen((data) {
      final command = data['command'];
      if (command != null) {
        setState(() {
          _lastCommand = command; // Update the UI with the latest command
        });
        _triggerVibration(); // Trigger vibration when a command is received
      }
    }, onError: (error) {
      print('Error listening for commands: $error');
      setState(() {
        _lastCommand = 'Error receiving command';
      });
    });
  }

  void _triggerVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500); // Vibrate for 500ms
      } else {
        print('Vibration not supported on this device');
      }
    } catch (e) {
      print('Error triggering vibration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Interface'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Last Command:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _lastCommand,
              style: TextStyle(fontSize: 20, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}