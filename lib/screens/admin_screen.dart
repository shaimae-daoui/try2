import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AdminScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Interface'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _firebaseService.sendCommand('applaud'),
              child: Text('Applaud'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _firebaseService.sendCommand('whistle'),
              child: Text('Whistle'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _firebaseService.sendCommand('chant'),
              child: Text('Chant'),
            ),
          ],
        ),
      ),
    );
  }
}