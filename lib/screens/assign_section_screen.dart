import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class AssignSectionScreen extends StatefulWidget {
  @override
  _AssignSectionScreenState createState() => _AssignSectionScreenState();
}

class _AssignSectionScreenState extends State<AssignSectionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _sections = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _firebaseService.getCurrentUser();
    if (user == null) return;

    // Charger les sections
    final maestroDoc = await _firestore.collection('maestros').doc(user.uid).get();
    if (maestroDoc.exists && maestroDoc.data()?['sections'] != null) {
      _sections = List<String>.from(maestroDoc.data()!['sections']);
    }

    // Charger tous les users (sauf maestros)
    final usersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();

    _users = usersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'name': data['fullName'] ?? 'Utilisateur',
        'phone': data['phoneNumber'] ?? '',
        'section': data['section'],
        'isVerified': data['isVerified'] ?? false,
      };
    }).toList();

    setState(() => _isLoading = false);
  }

  Future<void> _assignSection(String userUid, String section) async {
    await _firestore.collection('users').doc(userUid).update({
      'section': section,
    });

    setState(() {
      final userIndex = _users.indexWhere((u) => u['uid'] == userUid);
      if (userIndex != -1) {
        _users[userIndex]['section'] = section;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✓ Section attribuée')),
    );
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    if (_selectedSection == null) return _users;
    return _users.where((u) => u['section'] == _selectedSection).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Attribuer sections'),
          backgroundColor: Colors.orange[700],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: Text('Attribuer sections aux supporters'),
        backgroundColor: Colors.orange[700],
      ),
      body: Column(
        children: [
          // Filtre par section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrer par section',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text('Tous'),
                      selected: _selectedSection == null,
                      onSelected: (_) {
                        setState(() => _selectedSection = null);
                      },
                    ),
                    ..._sections.map((section) => FilterChip(
                      label: Text(section),
                      selected: _selectedSection == section,
                      onSelected: (_) {
                        setState(() => _selectedSection = section);
                      },
                    )).toList(),
                  ],
                ),
              ],
            ),
          ),

          // Statistiques
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total', _users.length.toString()),
                _buildStat('Assignés', _users.where((u) => u['section'] != null).length.toString()),
                _buildStat('Sans section', _users.where((u) => u['section'] == null).length.toString()),
              ],
            ),
          ),

          // Liste des utilisateurs
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
              child: Text(
                'Aucun supporter${_selectedSection != null ? " dans $_selectedSection" : ""}',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user['isVerified']
                          ? Colors.green[100]
                          : Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: user['isVerified']
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(user['name']),
                        if (user['isVerified'])
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['phone']),
                        if (user['section'] != null)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user['section'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (section) {
                        _assignSection(user['uid'], section);
                      },
                      itemBuilder: (context) => [
                        ..._sections.map((section) => PopupMenuItem(
                          value: section,
                          child: Text(section),
                        )).toList(),
                        if (user['section'] != null)
                          PopupMenuItem(
                            value: '',
                            child: Text(
                              'Retirer la section',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () async {
                              await _firestore
                                  .collection('users')
                                  .doc(user['uid'])
                                  .update({'section': FieldValue.delete()});
                              _loadData();
                            },
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

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}