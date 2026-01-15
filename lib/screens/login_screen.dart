import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import 'admin_screen.dart';
import 'supporter_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _maestroCodeController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isMaestroMode = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _maestroCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showMessage('Entrez votre numéro de téléphone');
      return;
    }

    String formattedPhone = phone;
    if (!phone.startsWith('+')) {
      if (phone.startsWith('0')) {
        formattedPhone = '+212${phone.substring(1)}';
      } else {
        formattedPhone = '+212$phone';
      }
    }

    // Si mode maestro, vérifier le code
    if (_isMaestroMode) {
      final code = _maestroCodeController.text.trim();
      if (code.isEmpty) {
        _showMessage('Entrez le code maestro');
        return;
      }

      setState(() {
        _isLoading = true;
        _statusMessage = 'Vérification du code maestro...';
      });

      final isValidCode = await _firebaseService.verifyMaestroCode(code);
      if (!isValidCode) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ Code maestro invalide ou déjà utilisé';
        });
        return;
      }

      // Vérifier si le numéro existe déjà
      final phoneExists = await _firebaseService.checkPhoneNumberExists(formattedPhone);
      if (phoneExists) {
        // Si le numéro existe, on va upgrader le compte en maestro
        setState(() {
          _statusMessage = '⚠️ Numéro déjà enregistré. Mise à niveau en maestro...';
        });
      }
    } else {
      // Mode user normal : vérifier que le numéro n'existe pas
      final phoneExists = await _firebaseService.checkPhoneNumberExists(formattedPhone);
      if (phoneExists) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ Ce numéro est déjà utilisé';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Envoi du code SMS...';
    });

    await _firebaseService.sendPhoneVerification(
      formattedPhone,
          (message) {
        setState(() {
          _isOtpSent = true;
          _statusMessage = message;
          _isLoading = false;
        });
      },
          (error) {
        setState(() {
          _statusMessage = error;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      _showMessage('Entrez le code à 6 chiffres');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Vérification...';
    });

    final user = await _firebaseService.verifyPhoneCode(otp);

    if (user != null) {
      final existingProfile = await _firebaseService.getUserProfile(user.uid);

      if (existingProfile != null) {
        // Compte existant
        if (_isMaestroMode) {
          // Upgrader en maestro
          await _firebaseService.updateUserRole(user.uid, 'maestro');
          await _firebaseService.useMaestroCode(_maestroCodeController.text.trim(), user.uid);

          existingProfile.role = 'maestro';
          setState(() {
            _statusMessage = '✓ Compte upgradé en Maestro !';
            _isLoading = false;
          });
        }
        _navigateBasedOnRole(existingProfile);
      } else {
        // Nouveau compte
        await _createNewUserProfile(user);
      }
    } else {
      setState(() {
        _statusMessage = 'Code invalide';
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewUserProfile(User user) async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Entrez votre nom');
      setState(() => _isLoading = false);
      return;
    }

    String role = 'user';
    bool isVerified = false;
    int reputationPoints = 0;
    String? sponsoredBy;

    if (_isMaestroMode) {
      // Mode Maestro
      role = 'maestro';
      isVerified = true;
      reputationPoints = 100;
      await _firebaseService.useMaestroCode(_maestroCodeController.text.trim(), user.uid);
    } else {
      // Mode User normal - vérifier code de parrainage si présent
      final sponsorshipCode = _maestroCodeController.text.trim();
      if (sponsorshipCode.isNotEmpty) {
        final maestroUid = await _firebaseService.verifySponsorshipCode(sponsorshipCode);
        if (maestroUid != null) {
          sponsoredBy = maestroUid;
          isVerified = true; // Parrainé = auto-vérifié
          reputationPoints = 20;
          setState(() {
            _statusMessage = '✓ Code de parrainage accepté !';
          });
        } else {
          setState(() {
            _statusMessage = '⚠️ Code de parrainage invalide (ignoré)';
          });
        }
      }
    }

    final newUser = UserModel(
      uid: user.uid,
      email: email.isEmpty ? 'user@maestro.app' : email,
      phoneNumber: user.phoneNumber ?? _phoneController.text.trim(),
      fullName: name,
      role: role,
      isVerified: isVerified,
      reputationPoints: reputationPoints,
    );

    // Créer le profil avec sponsoredBy si applicable
    await _firebaseService.createUserProfile(newUser);

    // Ajouter le champ sponsoredBy si parrainé
    if (sponsoredBy != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'sponsoredBy': sponsoredBy});
    }

    setState(() {
      _statusMessage = _isMaestroMode ? '✓ Compte Maestro créé !' : '✓ Compte créé !';
      _isLoading = false;
    });

    _navigateBasedOnRole(newUser);
  }

  void _navigateBasedOnRole(UserModel user) {
    if (user.isMaestro()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserScreen()),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                _isMaestroMode
                    ? Colors.orange.withOpacity(0.7)
                    : Colors.green.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(height: 40),

                  // Logo
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(
                      _isMaestroMode ? Icons.star : Icons.sports_soccer,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    'MAESTRO',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    _isMaestroMode ? 'Mode Maestro' : 'Synchronisez les supporters',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  SizedBox(height: 30),

                  // Toggle Maestro/User
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Supporter',
                        style: TextStyle(
                          color: !_isMaestroMode ? Colors.white : Colors.white60,
                          fontWeight: !_isMaestroMode ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      SizedBox(width: 12),
                      Switch(
                        value: _isMaestroMode,
                        onChanged: (value) {
                          setState(() {
                            _isMaestroMode = value;
                            _statusMessage = '';
                          });
                        },
                        activeColor: Colors.orange[700],
                      ),
                      SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(Icons.star, color: _isMaestroMode ? Colors.white : Colors.white60, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Maestro',
                            style: TextStyle(
                              color: _isMaestroMode ? Colors.white : Colors.white60,
                              fontWeight: _isMaestroMode ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Formulaire
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (!_isOtpSent) ...[
                          // Code Maestro (si mode maestro activé)
                          if (_isMaestroMode) ...[
                            _buildTextField(
                              controller: _maestroCodeController,
                              label: 'Code Maestro',
                              hint: 'RAJA-M-2024-XXXX',
                              icon: Icons.vpn_key,
                            ),
                            SizedBox(height: 16),
                          ],

                          // Code de parrainage (si mode user)
                          if (!_isMaestroMode) ...[
                            _buildTextField(
                              controller: _maestroCodeController,
                              label: 'Code de parrainage (optionnel)',
                              hint: 'M-ABC123',
                              icon: Icons.card_giftcard,
                            ),
                            Text(
                              'Si vous avez un code d\'un maestro',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],

                          _buildTextField(
                            controller: _phoneController,
                            label: 'Numéro de téléphone',
                            hint: '0612345678',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nom complet',
                            hint: 'Votre nom',
                            icon: Icons.person,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email (optionnel)',
                            hint: 'email@example.com',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ] else ...[
                          _buildTextField(
                            controller: _otpController,
                            label: 'Code de vérification',
                            hint: '123456',
                            icon: Icons.lock,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                          ),
                        ],

                        SizedBox(height: 20),

                        if (_statusMessage.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _statusMessage.contains('❌')
                                  ? Colors.red[50]
                                  : (_isMaestroMode ? Colors.orange[50] : Colors.green[50]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _statusMessage.contains('❌')
                                    ? Colors.red[800]
                                    : (_isMaestroMode ? Colors.orange[800] : Colors.green[800]),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        SizedBox(height: 20),

                        if (_isLoading)
                          CircularProgressIndicator(
                            color: _isMaestroMode ? Colors.orange[700] : Colors.green[700],
                          )
                        else if (!_isOtpSent)
                          _buildButton(
                            text: 'Envoyer le code',
                            onPressed: _sendOtp,
                            color: _isMaestroMode ? Colors.orange[700]! : Colors.green[700]!,
                          )
                        else ...[
                            _buildButton(
                              text: 'Vérifier',
                              onPressed: _verifyOtp,
                              color: _isMaestroMode ? Colors.orange[700]! : Colors.green[700]!,
                            ),
                            SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                  _statusMessage = '';
                                });
                              },
                              child: Text(
                                'Changer de numéro',
                                style: TextStyle(
                                  color: _isMaestroMode ? Colors.orange[700] : Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _isMaestroMode ? Colors.orange[200]! : Colors.green[200]!,
          width: 2,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: _isMaestroMode ? Colors.orange[700] : Colors.green[700],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}