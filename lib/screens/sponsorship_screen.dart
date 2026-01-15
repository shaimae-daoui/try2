import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firebase_service.dart';
import 'dart:math';

class SponsorshipScreen extends StatefulWidget {
  @override
  _SponsorshipScreenState createState() => _SponsorshipScreenState();
}

class _SponsorshipScreenState extends State<SponsorshipScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _sponsorshipCode;
  int _sponsoredCount = 0;
  int _maxSponsorships = 2;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sponsoredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadSponsorshipData();
  }

  Future<void> _loadSponsorshipData() async {
    final user = _firebaseService.getCurrentUser();
    if (user == null) return;

    setState(() => _isLoading = true);

    // Charger ou créer le code de parrainage
    final maestroDoc = await _firestore.collection('maestros').doc(user.uid).get();

    if (maestroDoc.exists && maestroDoc.data()?['sponsorshipCode'] != null) {
      _sponsorshipCode = maestroDoc.data()!['sponsorshipCode'];
    } else {
      // Créer un nouveau code
      _sponsorshipCode = _generateSponsorshipCode();
      await _firestore.collection('maestros').doc(user.uid).set({
        'sponsorshipCode': _sponsorshipCode,
        'createdAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    // Compter les parrainés
    final sponsoredSnapshot = await _firestore
        .collection('users')
        .where('sponsoredBy', isEqualTo: user.uid)
        .get();

    _sponsoredUsers = sponsoredSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['fullName'] ?? 'Utilisateur',
        'phone': data['phoneNumber'] ?? '',
        'joinedAt': data['createdAt'] ?? '',
      };
    }).toList();

    setState(() {
      _sponsoredCount = sponsoredSnapshot.docs.length;
      _isLoading = false;
    });
  }

  String _generateSponsorshipCode() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return 'M-$code';
  }

  void _copyCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: _sponsorshipCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Code copié : $_sponsorshipCode'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareCode() {
    final message = '''
🎉 Rejoins MAESTRO avec mon code de parrainage !

Code : $_sponsorshipCode

Tu seras automatiquement vérifié et pourras participer aux tifos synchronisés au stade ! ⚽

Télécharge l'app et utilise mon code lors de l'inscription.
''';

    Share.share(message, subject: 'Code de parrainage MAESTRO');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Parrainage'),
          backgroundColor: Colors.orange[700],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canSponsor = _sponsoredCount < _maxSponsorships;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[700]!, Colors.orange[300]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Parrainage',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Statut
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: canSponsor ? Colors.green[50] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: canSponsor ? Colors.green[300]! : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                canSponsor ? Icons.check_circle : Icons.block,
                                size: 60,
                                color: canSponsor ? Colors.green : Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                '$_sponsoredCount / $_maxSponsorships parrainages',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: canSponsor ? Colors.green[800] : Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                canSponsor
                                    ? 'Vous pouvez parrainer ${_maxSponsorships - _sponsoredCount} personne(s)'
                                    : 'Limite de parrainages atteinte',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        if (canSponsor) ...[
                          // Code de parrainage
                          Text(
                            'Votre code de parrainage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.orange[300]!, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _sponsorshipCode!,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                    fontFamily: 'Courier',
                                    color: Colors.orange[900],
                                  ),
                                ),
                                SizedBox(width: 12),
                                IconButton(
                                  icon: Icon(Icons.copy, color: Colors.orange[700]),
                                  onPressed: _copyCodeToClipboard,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Bouton partager
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: _shareCode,
                              icon: Icon(Icons.share),
                              label: Text(
                                'Partager le code',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 30),

                          // Instructions
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.blue[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Comment ça marche ?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                _buildInstructionItem('1', 'Partagez ce code avec 2 supporters de confiance'),
                                _buildInstructionItem('2', 'Ils s\'inscrivent avec votre code'),
                                _buildInstructionItem('3', 'Ils deviennent automatiquement vérifiés'),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 30),

                        // Liste des parrainés
                        if (_sponsoredUsers.isNotEmpty) ...[
                          Text(
                            'Supporters parrainés',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 16),
                          ..._sponsoredUsers.map((user) => Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.orange[100],
                                  child: Icon(Icons.person, color: Colors.orange[700]),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        user['phone'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.check_circle, color: Colors.green),
                              ],
                            ),
                          )).toList(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}