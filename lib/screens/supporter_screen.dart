import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../services/firebase_service.dart';
import 'profile_screen.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String _lastCommand = 'En attente de commande...';
  final FirebaseService _firebaseService = FirebaseService();
  Color _commandColor = Colors.grey;
  IconData _commandIcon = Icons.hearing;

  @override
  void initState() {
    super.initState();
    _listenForCommands();
  }

  void _listenForCommands() {
    _firebaseService.listenForCommands().listen((data) {
      final command = data['command'];
      if (command != null) {
        setState(() {
          _lastCommand = _getCommandText(command);
          _commandColor = _getCommandColor(command);
          _commandIcon = _getCommandIcon(command);
        });
        _triggerVibration();
      }
    }, onError: (error) {
      print('Erreur: $error');
      setState(() {
        _lastCommand = 'Erreur de réception';
        _commandColor = Colors.red;
      });
    });
  }

  String _getCommandText(String command) {
    switch (command) {
      case 'applaud':
        return '👏 APPLAUDISSEZ !';
      case 'whistle':
        return '📢 SIFFLEZ !';
      case 'chant':
        return '🎵 CHANTEZ !';
      case 'silence':
        return '🤫 SILENCE !';
      default:
        return command.toUpperCase();
    }
  }

  Color _getCommandColor(String command) {
    switch (command) {
      case 'applaud':
        return Colors.green;
      case 'whistle':
        return Colors.orange;
      case 'chant':
        return Colors.blue;
      case 'silence':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  IconData _getCommandIcon(String command) {
    switch (command) {
      case 'applaud':
        return Icons.back_hand;
      case 'whistle':
        return Icons.campaign;
      case 'chant':
        return Icons.music_note;
      case 'silence':
        return Icons.volume_off;
      default:
        return Icons.sports_soccer;
    }
  }

  void _triggerVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      print('Erreur vibration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[700]!,
              Colors.green[400]!,
              Colors.lightGreen[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec profil
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAESTRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Mode Supporter',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            color: Colors.green[700],
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône de commande animée
                      Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: _commandColor.withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            _commandIcon,
                            size: 80,
                            color: _commandColor,
                          ),
                        ),
                      ),

                      SizedBox(height: 40),

                      // Texte de commande
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 40),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Dernière commande :',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              _lastCommand,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _commandColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Indicateur de connexion
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Connecté',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}