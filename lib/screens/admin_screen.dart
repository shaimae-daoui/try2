import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'profile_screen.dart';
import 'assign_section_screen.dart';
import 'songs_playlist_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedSection;
  int _connectedUsers = 0;
  int _totalCommands = 0;
  String _lastCommandSent = 'Aucune commande';

  List<String> _sections = ['Tous'];
  List<Map<String, dynamic>> _commands = [
    {
      'name': 'Applaudir',
      'command': 'applaud',
      'icon': Icons.back_hand,
      'color': Colors.green,
    },
    {
      'name': 'Siffler',
      'command': 'whistle',
      'icon': Icons.campaign,
      'color': Colors.orange,
    },
    {
      'name': 'Chanter',
      'command': 'chant',
      'icon': Icons.music_note,
      'color': Colors.blue,
    },
    {
      'name': 'Silence',
      'command': 'silence',
      'icon': Icons.volume_off,
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSection = 'Tous';
    _loadSections();
    _loadStats();
  }

  Future<void> _loadSections() async {
    // Charger les sections depuis Firestore
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      final doc = await _firestore.collection('maestros').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['sections'] != null) {
          setState(() {
            _sections = ['Tous', ...List<String>.from(data['sections'])];
          });
        }
      }
    }
  }

  Future<void> _loadStats() async {
    // Charger vraies statistiques
    final usersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'user').get();

    setState(() {
      _connectedUsers = usersSnapshot.docs.length;
    });
  }

  void _sendCommand(String command, String commandName) {
    final section = _selectedSection == 'Tous' ? null : _selectedSection;
    _firebaseService.sendCommand(command, section: section);

    setState(() {
      _lastCommandSent = '$commandName ${section != null ? "→ $section" : "→ Tous"}';
      _totalCommands++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Commande envoyée : $commandName'),
        backgroundColor: Colors.green[700],
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddSectionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter une section'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nom de la section',
            hintText: 'Ex: Amphi A, Virage Nord',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final sectionName = controller.text.trim();
              if (sectionName.isNotEmpty) {
                await _addSection(sectionName);
                Navigator.pop(context);
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSection(String sectionName) async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      final newSections = [..._sections.where((s) => s != 'Tous'), sectionName];

      await _firestore.collection('maestros').doc(user.uid).set({
        'sections': newSections,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      setState(() {
        _sections = ['Tous', ...newSections];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Section "$sectionName" ajoutée')),
      );
    }
  }

  void _showAddCommandDialog() {
    final nameController = TextEditingController();
    final commandController = TextEditingController();
    Color selectedColor = Colors.purple;
    IconData selectedIcon = Icons.star;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Créer une commande'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom affiché',
                    hintText: 'Ex: Lever écharpe',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: commandController,
                  decoration: InputDecoration(
                    labelText: 'Commande (technique)',
                    hintText: 'Ex: raise_scarf',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text('Couleur:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.red, Colors.blue, Colors.green, Colors.orange,
                    Colors.purple, Colors.pink, Colors.teal, Colors.amber,
                  ].map((color) => GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  )).toList(),
                ),
                SizedBox(height: 16),
                Text('Icône:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    Icons.flag, Icons.flashlight_on, Icons.favorite,
                    Icons.sports_soccer, Icons.celebration, Icons.theater_comedy,
                    Icons.waving_hand, Icons.thumb_up,
                  ].map((icon) => GestureDetector(
                    onTap: () => setDialogState(() => selectedIcon = icon),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: selectedIcon == icon ? Colors.grey[300] : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 30),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final command = commandController.text.trim();
                if (name.isNotEmpty && command.isNotEmpty) {
                  setState(() {
                    _commands.add({
                      'name': name,
                      'command': command,
                      'icon': selectedIcon,
                      'color': selectedColor,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✓ Commande "$name" créée')),
                  );
                }
              },
              child: Text('Créer'),
            ),
          ],
        ),
      ),
    );
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
              Colors.orange[800]!,
              Colors.orange[600]!,
              Colors.deepOrange[400]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsBar(),

              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionSelector(),

                        SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Commandes',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SongsPlaylistScreen(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.music_note, size: 18),
                                  label: Text('Chants'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _showAddCommandDialog,
                                  icon: Icon(Icons.add, size: 20),
                                  label: Text('Créer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildCommandsGrid(),

                        SizedBox(height: 24),
                        _buildLastCommand(),
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

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'MAESTRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Contrôle des supporters',
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
                MaterialPageRoute(builder: (context) => ProfileScreen()),
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
                  color: Colors.orange[800],
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.people, '$_connectedUsers', 'Supporters'),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem(Icons.send, '$_totalCommands', 'Commandes'),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem(Icons.grid_view, '${_sections.length - 1}', 'Sections'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Section du stade',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.orange[700]),
              onPressed: _showAddSectionDialog,
              tooltip: 'Ajouter une section',
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final section = _sections[index];
              final isSelected = _selectedSection == section;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSection = section;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ]
                        : [],
                  ),
                  child: Text(
                    section,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommandsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _commands.length,
      itemBuilder: (context, index) {
        final cmd = _commands[index];
        return GestureDetector(
          onTap: () => _sendCommand(cmd['command'], cmd['name']),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cmd['color'],
                  cmd['color'].withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cmd['color'].withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cmd['icon'],
                  size: 50,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  cmd['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLastCommand() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.orange[700]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dernière commande',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _lastCommandSent,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}