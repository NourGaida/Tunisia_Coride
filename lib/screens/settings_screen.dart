import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // NOUVEAU
  final TextEditingController _newPasswordController =
      TextEditingController(); // NOUVEAU
  final TextEditingController _currentPasswordController =
      TextEditingController(); // NOUVEAU

  // État
  bool _isLoading = true;
  bool _isSaving = false;
  String? _avatarUrl;
  File? _localImageFile;
  String _selectedGender = 'Non spécifié';
  bool _hasDriverLicense = false;

  bool _obscureNewPassword =
      true; // Pour masquer/afficher le nouveau mot de passe
  bool _obscureCurrentPassword =
      true; // Pour masquer/afficher le mot de passe actuel

  final List<String> _genderOptions = ['Homme', 'Femme', 'Non spécifié'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose(); // NOUVEAU
    _newPasswordController.dispose(); // NOUVEAU
    _currentPasswordController.dispose(); // NOUVEAU
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;

        setState(() {
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = currentUser.email ??
              ''; // Initialiser avec l'email actuel de Firebase Auth
          _avatarUrl = data['avatarUrl'];
          _selectedGender = data['gender'] ?? 'Non spécifié';
          _hasDriverLicense = data['hasDriverLicense'] ?? false;
          _isLoading = false;
        });
      } else {
        // Cas où le document utilisateur n'existe pas, mais l'utilisateur est connecté via Auth
        if (mounted) {
          setState(() {
            _emailController.text = currentUser.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _localImageFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
      _showSnackBar('Erreur lors de la sélection de l\'image', isError: true);
    }
  }

  Future<void> _removeAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text(
          'Voulez-vous vraiment supprimer votre photo de profil ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _localImageFile = null;
        _avatarUrl = null;
      });
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    // ... (Logique inchangée pour l'upload, nécessite Firebase Storage et ses règles) ...
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${currentUser.uid}.jpg');

      try {
        await storageRef.delete();
      } catch (e) {
        debugPrint('Ancienne image inexistante: $e');
      }

      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': currentUser.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('✅ Image uploadée: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload image: $e');
      return null;
    }
  }

  Future<void> _deleteImageFromStorage() async {
    // ... (Logique inchangée) ...
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${currentUser.uid}.jpg');

      await storageRef.delete();
      debugPrint('✅ Image supprimée du storage');
    } catch (e) {
      debugPrint('❌ Erreur suppression image: $e');
    }
  }

  Future<void> _reauthenticateUser(User user) async {
    String currentPassword = _currentPasswordController.text.trim();
    if (currentPassword.isEmpty) {
      throw Exception(
        "Veuillez entrer votre mot de passe actuel pour des raisons de sécurité.",
      );
    }

    AuthCredential credential = EmailAuthProvider.credential(
      email: user
          .email!, // On suppose que l'email est non null si on re-authentifie un user
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ Utilisateur re-authentifié avec succès.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Mot de passe actuel incorrect.");
      } else if (e.code == 'user-not-found') {
        throw Exception("Utilisateur non trouvé.");
      } else {
        throw Exception("Erreur de re-authentification: ${e.message}");
      }
    } catch (e) {
      throw Exception("Erreur inattendue lors de la re-authentification.");
    }
  }

  Future<void> _saveChanges() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar(
        'Vous devez être connecté pour sauvegarder les modifications',
        isError: true,
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Le nom est obligatoire', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> updates = {
        'name': name,
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'hasDriverLicense': _hasDriverLicense,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_localImageFile != null) {
        _showSnackBar('Upload de l\'image en cours...', isError: false);
        final uploadedUrl = await _uploadImageToStorage(_localImageFile!);
        if (uploadedUrl != null) {
          updates['avatarUrl'] = uploadedUrl;
          _showSnackBar('Image uploadée avec succès !', isError: false);
        } else {
          throw Exception('Échec de l\'upload de l\'image');
        }
      } else if (_avatarUrl == null) {
        await _deleteImageFromStorage();
        updates['avatarUrl'] = FieldValue.delete();
      }

      final newEmail = _emailController.text.trim();
      if (newEmail.isNotEmpty && newEmail != currentUser.email) {
        debugPrint('Tentative de mise à jour de l\'email vers: $newEmail');
        await _reauthenticateUser(currentUser); // Re-authentification requise
        await currentUser.verifyBeforeUpdateEmail(newEmail);
        updates['email'] = newEmail; // Mettre à jour dans Firestore également
        _showSnackBar('Email mis à jour !', isError: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Un e-mail de vérification a été envoyé à $newEmail. '
                'Veuillez cliquer sur le lien dans cet e-mail pour confirmer le changement. '
                'Votre e-mail de connexion ne sera mis à jour qu\'après cette vérification.',
              ),
              backgroundColor: AppColors.success, // Couleur de succès
              duration: const Duration(
                  seconds: 5), // Laisse le message plus longtemps
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          );
        }
      }

      // ✅ GESTION DE LA MISE À JOUR DU MOT DE PASSE
      final newPassword = _newPasswordController.text.trim();
      if (newPassword.isNotEmpty) {
        debugPrint('Tentative de mise à jour du mot de passe...');
        await _reauthenticateUser(currentUser); // Re-authentification requise
        await currentUser.updatePassword(newPassword);
        _showSnackBar('Mot de passe mis à jour !', isError: false);
        _newPasswordController.clear(); // Effacer le champ après la mise à jour
        _currentPasswordController.clear(); // Effacer le mot de passe actuel
      }

      // Sauvegarder les modifications du document utilisateur dans Firestore
      await _firestore.collection('users').doc(currentUser.uid).update(updates);

      if (mounted) {
        _showSnackBar('Modifications enregistrées !', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true); // Retour avec succès
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Erreur lors de la mise à jour';
      if (e.code == 'requires-recent-login') {
        errorMessage =
            'Veuillez entrer votre mot de passe actuel et réessayer.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'L\'adresse email est mal formatée.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Cette adresse email est déjà utilisée.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Le nouveau mot de passe est trop faible.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      _showSnackBar(errorMessage, isError: true);
      debugPrint('❌ Erreur FirebaseAuth: ${e.code} - ${e.message}');
    } on Exception catch (e) {
      debugPrint('❌ Erreur: $e');
      if (mounted) {
        _showSnackBar(
          e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception: ', '')
              : 'Erreur lors de la sauvegarde',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde: $e');
      if (mounted) {
        _showSnackBar(
          e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception: ', '')
              : 'Erreur lors de la sauvegarde',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo de profil
            _buildAvatarSection(),

            const SizedBox(height: 32),

            // Informations personnelles
            _buildSectionTitle('Informations personnelles'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Nom complet',
              icon: Icons.person,
              hint: 'Votre nom',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.info_outline,
              hint: 'Parlez de vous...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildGenderSelector(),

            const SizedBox(height: 32),

            // Contact
            _buildSectionTitle('Contact'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: Icons.phone,
              hint: '+216 XX XXX XXX',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              // NOUVEAU : Champ Email
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              hint: 'votre.email@exemple.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),

            // Sécurité
            _buildSectionTitle('Sécurité'), // NOUVEAU
            const SizedBox(height: 16),
            _buildPasswordField(
              // NOUVEAU : Champ pour nouveau mot de passe
              controller: _newPasswordController,
              label: 'Nouveau mot de passe',
              hint: 'Laisser vide pour ne pas changer',
              obscureText: _obscureNewPassword,
              onVisibilityToggle: () {
                setState(() => _obscureNewPassword = !_obscureNewPassword);
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              // NOUVEAU : Champ pour mot de passe actuel
              controller: _currentPasswordController,
              label: 'Mot de passe actuel',
              hint: 'Requis pour changer l\'email ou le mot de passe',
              obscureText: _obscureCurrentPassword,
              onVisibilityToggle: () {
                setState(
                  () => _obscureCurrentPassword = !_obscureCurrentPassword,
                );
              },
            ),

            const SizedBox(height: 32),

            // Permis de conduire
            _buildSectionTitle('Conduite'),
            const SizedBox(height: 16),
            _buildDriverLicenseSwitch(),

            const SizedBox(height: 40),

            // Bouton sauvegarder
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: _localImageFile != null
                ? ClipOval(
                    child: Image.file(_localImageFile!, fit: BoxFit.cover),
                  )
                : _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        ),
                      )
                    : _buildDefaultAvatar(),
          ),

          // Bouton modifier
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Bouton supprimer (si image existe)
          if (_avatarUrl != null || _localImageFile != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: _removeAvatar,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final name = _nameController.text.trim();
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    // NOUVEAU : Widget pour les champs de mot de passe
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.lock,
                color: AppColors.textMuted,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: onVisibilityToggle,
              ),
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sexe',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textMuted,
              ),
              items: _genderOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'Homme'
                            ? Icons.male
                            : value == 'Femme'
                                ? Icons.female
                                : Icons.person_outline,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverLicenseSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _hasDriverLicense
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.card_membership,
              color:
                  _hasDriverLicense ? AppColors.success : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permis de conduire',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasDriverLicense ? 'Vérifié' : 'Non vérifié',
                  style: TextStyle(
                    fontSize: 13,
                    color: _hasDriverLicense
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _hasDriverLicense,
            onChanged: (value) {
              setState(() {
                _hasDriverLicense = value;
              });
            },
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}
