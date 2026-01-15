import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'song_karaoke_screen.dart';

class SongsPlaylistScreen extends StatefulWidget {
  @override
  _SongsPlaylistScreenState createState() => _SongsPlaylistScreenState();
}

class _SongsPlaylistScreenState extends State<SongsPlaylistScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final snapshot = await _firestore.collection('songs').get();

    setState(() {
      _songs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _isLoading = false;
    });

    // Si aucune chanson, créer des exemples
    if (_songs.isEmpty) {
      await _createDefaultSongs();
      _loadSongs();
    }
  }

  Future<void> _createDefaultSongs() async {
    final defaultSongs = [
      {
        'title': 'Allez Allez',
        'team': 'Raja',
        'lyrics': 'Allez allez allez|Raja Casa|On est là on est là|Pour gagner ce soir',
        'duration': 20,
      },
      {
        'title': 'Ya Wydad',
        'team': 'Wydad',
        'lyrics': 'Ya Wydad ya Wydad|Champion d\'Afrique|On est les meilleurs|Du Maroc entier',
        'duration': 20,
      },
      {
        'title': 'Dima Raja',
        'team': 'Raja',
        'lyrics': 'Dima Raja dima|On ne lâche rien|Victoire victoire|Pour nos couleurs',
        'duration': 20,
      },
    ];

    for (final song in defaultSongs) {
      await _firestore.collection('songs').add(song);
    }
  }

  Future<void> _sendSongCommand(Map<String, dynamic> song) async {
    _firebaseService.sendCommand('song', section: null);

    // Envoyer aussi les données de la chanson
    await _firestore.collection('current_song').doc('active').set({
      'songId': song['id'],
      'title': song['title'],
      'lyrics': song['lyrics'],
      'startedAt': DateTime.now().toIso8601String(),
      'duration': song['duration'] ?? 30,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎵 Chanson "${song['title']}" envoyée'),
        backgroundColor: Colors.green,
      ),
    );

    // Ouvrir l'aperçu karaoké
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongKaraokeScreen(song: song),
      ),
    );
  }

  void _showAddSongDialog() {
    final titleController = TextEditingController();
    final lyricsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un chant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Titre du chant',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: lyricsController,
                decoration: InputDecoration(
                  labelText: 'Paroles (séparer par |)',
                  hintText: 'Ligne 1|Ligne 2|Ligne 3',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 8),
              Text(
                'Séparez chaque ligne par le symbole |',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
            onPressed: () async {
              final title = titleController.text.trim();
              final lyrics = lyricsController.text.trim();

              if (title.isNotEmpty && lyrics.isNotEmpty) {
                await _firestore.collection('songs').add({
                  'title': title,
                  'team': 'Custom',
                  'lyrics': lyrics,
                  'duration': 30,
                  'createdAt': DateTime.now().toIso8601String(),
                });

                Navigator.pop(context);
                _loadSongs();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Chant ajouté')),
                );
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Playlist de chants'),
          backgroundColor: Colors.orange[700],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Playlist de chants'),
        backgroundColor: Colors.orange[700],
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddSongDialog,
          ),
        ],
      ),
      body: _songs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun chant disponible',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddSongDialog,
              icon: Icon(Icons.add),
              label: Text('Ajouter un chant'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          final lyricsLines = (song['lyrics'] as String).split('|');

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 3,
            child: InkWell(
              onTap: () => _sendSongCommand(song),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: Colors.orange[700],
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song['title'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  song['team'] ?? 'Général',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.play_circle,
                          size: 40,
                          color: Colors.green[700],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Aperçu des paroles :',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...lyricsLines.take(3).map((line) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    )).toList(),
                    if (lyricsLines.length > 3)
                      Text(
                        '...',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}