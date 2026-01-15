import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import 'sponsorship_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      final profile = await _firebaseService.getUserProfile(user.uid);

      if (profile == null) {
        // Profil n'existe pas, créer un profil par défaut
        print('⚠️ Profil non trouvé, création d\'un profil par défaut...');
        final newProfile = UserModel(
          uid: user.uid,
          email: user.email ?? 'user@maestro.app',
          phoneNumber: user.phoneNumber ?? '',
          fullName: user.displayName ?? 'Utilisateur',
          role: 'user',
          isVerified: false,
        );

        await _firebaseService.createUserProfile(newProfile);

        setState(() {
          _currentUser = newProfile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentUser = profile;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profil'),
          backgroundColor: Colors.green[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'Erreur de chargement du profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Essayez de vous déconnecter et reconnecter',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  await _firebaseService.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: Icon(Icons.logout),
                label: Text('Déconnexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[700]!, Colors.green[300]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                      Spacer(),
                      Text(
                        'Mon Profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.settings, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Avatar
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.green[700],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Nom
                Text(
                  _currentUser!.fullName ?? 'Utilisateur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                // Badge rôle
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _currentUser!.isMaestro()
                        ? Colors.orange[700]
                        : Colors.blue[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentUser!.isMaestro()
                            ? Icons.star
                            : Icons.sports_soccer,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        _currentUser!.isMaestro() ? 'MAESTRO' : 'SUPPORTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Carte d'informations
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
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
                      _buildInfoRow(
                        Icons.phone,
                        'Téléphone',
                        _currentUser!.phoneNumber,
                      ),
                      Divider(height: 30),
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        _currentUser!.email,
                      ),
                      Divider(height: 30),
                      _buildInfoRow(
                        Icons.sports_soccer,
                        'Équipe',
                        _currentUser!.team ?? 'Non définie',
                      ),
                      Divider(height: 30),
                      _buildInfoRow(
                        Icons.verified,
                        'Statut',
                        _currentUser!.isVerified ? 'Vérifié ✓' : 'Non vérifié',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Statistiques
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(20),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        '${_currentUser!.reputationPoints}',
                        'Points',
                        Icons.star,
                        Colors.orange[700]!,
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                      _buildStatCard(
                        '0',
                        'Matchs',
                        Icons.stadium,
                        Colors.blue[700]!,
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                      _buildStatCard(
                        _currentUser!.canSponsor() ? '2 disponibles' : 'Non autorisé',
                        'Parrainages',
                        Icons.people,
                        Colors.green[700]!,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Bouton parrainage (si maestro)
                if (_currentUser!.isMaestro())
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SponsorshipScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.people),
                        label: Text(
                          'Parrainer des supporters',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 20),

                // Bouton déconnexion
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _firebaseService.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: Icon(Icons.logout),
                      label: Text(
                        'Déconnexion',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.green[700]),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}