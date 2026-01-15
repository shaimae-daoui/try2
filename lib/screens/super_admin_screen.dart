import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SuperAdminScreen extends StatefulWidget {
  @override
  _SuperAdminScreenState createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _teamController = TextEditingController();
  List<Map<String, dynamic>> _codes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _isLoading = true);

    final snapshot = await _firestore
        .collection('maestro_codes')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _codes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['code'] = doc.id;
        return data;
      }).toList();
      _isLoading = false;
    });
  }

  String _generateCode(String team) {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final randomPart = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final year = DateTime.now().year;
    return '${team.toUpperCase()}-M-$year-$randomPart';
  }

  Future<void> _createCode() async {
    final team = _teamController.text.trim();
    if (team.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entrez le nom de l\'équipe')),
      );
      return;
    }

    final code = _generateCode(team);
    final expiresAt = DateTime.now().add(Duration(days: 30));

    await _firestore.collection('maestro_codes').doc(code).set({
      'team': team,
      'used': false,
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': 'super_admin',
      'expiresAt': expiresAt.toIso8601String(),
    });

    _teamController.clear();
    _loadCodes();

    // Copier le code dans le presse-papier
    Clipboard.setData(ClipboardData(text: code));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Code créé et copié: $code'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _revokeCode(String code) async {
    await _firestore.collection('maestro_codes').doc(code).update({
      'used': true,
      'revokedAt': DateTime.now().toIso8601String(),
    });
    _loadCodes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Super Admin - Codes Maestro'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Formulaire de création
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.deepPurple[50],
            child: Column(
              children: [
                TextField(
                  controller: _teamController,
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'équipe',
                    hintText: 'Ex: Raja, Wydad, FAR',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createCode,
                    icon: Icon(Icons.add),
                    label: Text('Générer un code maestro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des codes
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _codes.isEmpty
                ? Center(child: Text('Aucun code créé'))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _codes.length,
              itemBuilder: (context, index) {
                final codeData = _codes[index];
                final isUsed = codeData['used'] ?? false;
                final code = codeData['code'];
                final team = codeData['team'];
                final expiresAt = codeData['expiresAt'] != null
                    ? DateTime.parse(codeData['expiresAt'])
                    : null;
                final isExpired = expiresAt != null &&
                    expiresAt.isBefore(DateTime.now());

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUsed || isExpired
                          ? Colors.grey
                          : Colors.green,
                      child: Icon(
                        isUsed || isExpired ? Icons.block : Icons.check,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Équipe: $team'),
                        Text(
                          isUsed
                              ? '❌ Utilisé'
                              : isExpired
                              ? '⏰ Expiré'
                              : '✓ Disponible',
                          style: TextStyle(
                            color: isUsed || isExpired
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Code copié')),
                            );
                          },
                        ),
                        if (!isUsed && !isExpired)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _revokeCode(code),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}