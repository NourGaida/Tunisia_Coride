import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importez FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Importez Cloud Firestore
import '../utils/constants.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers pour Connexion
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Controllers pour Inscription
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPhoneController = TextEditingController();
  final TextEditingController _signupPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Instances de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si la connexion réussit, naviguez vers HomeScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé pour cet email.';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          message = 'L\'adresse email est mal formatée.';
          break;
        case 'invalid-credential': // Pour les versions récentes de Firebase Auth
          message = 'Identifiants invalides.';
          break;
        default:
          message = 'Erreur de connexion : ${e.message}';
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar('Une erreur inattendue est survenue: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSignup() async {
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final phone = _signupPhoneController.text.trim();
    final password = _signupPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Créer l'utilisateur avec Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Stocker les informations supplémentaires dans Cloud Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt':
              FieldValue.serverTimestamp(), // Ajoute un timestamp du serveur
        });
      }

      // Si l'inscription réussit et les données Firestore sont enregistrées, naviguez vers HomeScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Le mot de passe fourni est trop faible.';
          break;
        case 'email-already-in-use':
          message = 'Un compte existe déjà pour cette adresse email.';
          break;
        case 'invalid-email':
          message = 'L\'adresse email est mal formatée.';
          break;
        default:
          message = 'Erreur d\'inscription : ${e.message}';
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar('Une erreur inattendue est survenue: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  // Logo + Titre
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // Carte principale
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.05), // Correction ici
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Onglets
                        _buildTabs(),

                        const SizedBox(height: 24),

                        // Contenu des onglets
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: _tabController.index == 0
                              ? _buildLoginForm()
                              : _buildSignupForm(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Conditions d'utilisation
                  _buildTermsText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🎨 HEADER (Logo + Titre)
  // ═══════════════════════════════════════════════
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3), // Correction ici
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              AppAssets.logo,
              width: 50,
              height: 50,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.directions_car,
                  size: 40,
                  color: Colors.white,
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Titre
        const Text(
          'CoRide',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),

        const SizedBox(height: 4),

        // Sous-titre
        const Text(
          'Connecting your journeys',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // 📑 ONGLETS (Connexion / Inscription)
  // ═══════════════════════════════════════════════
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // Correction ici
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(5),
        labelColor: AppColors.primary,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Connexion"),
          Tab(text: "Inscription"),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🔐 FORMULAIRE CONNEXION
  // ═══════════════════════════════════════════════
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email ou téléphone
        _buildLabel('Email ou téléphone'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _loginEmailController,
          hint: 'exemple@email.com',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // Mot de passe
        _buildLabel('Mot de passe'),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _loginPasswordController,
        ),

        const SizedBox(height: 12),

        // Mot de passe oublié
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // TODO: Implémenter la récupération de mot de passe Firebase
              // Exemple: await _auth.sendPasswordResetEmail(email: _loginEmailController.text.trim());
              _showSnackBar(
                  'Fonctionnalité de récupération de mot de passe à venir');
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Mot de passe oublié ?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Bouton Se connecter
        _buildSubmitButton(
          text: 'Se connecter',
          onPressed: _handleLogin,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // 📝 FORMULAIRE INSCRIPTION
  // ═══════════════════════════════════════════════
  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nom complet
        _buildLabel('Nom complet'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _signupNameController,
          hint: 'Votre nom',
          keyboardType: TextInputType.name,
        ),

        const SizedBox(height: 16),

        // Email
        _buildLabel('Email'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _signupEmailController,
          hint: 'exemple@email.com',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // Téléphone
        _buildLabel('Téléphone'),
        const SizedBox(height: 8),
        _buildPhoneField(
          controller: _signupPhoneController,
        ),

        const SizedBox(height: 16),

        // Mot de passe
        _buildLabel('Mot de passe'),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _signupPasswordController,
        ),

        const SizedBox(height: 24),

        // Bouton S'inscrire
        _buildSubmitButton(
          text: "S'inscrire",
          onPressed: _handleSignup,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // 🧩 COMPOSANTS RÉUTILISABLES (inchangés ou avec corrections cosmétiques)
  // ═══════════════════════════════════════════════

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111827),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111827),
        ),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          // Préfixe +216
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: const Row(
              children: [
                Text('🇹🇳', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  '+216',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),

          // Input téléphone
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
              decoration: const InputDecoration(
                hintText: 'XX XXX XXX',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3), // Correction ici
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return const Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF9CA3AF),
          height: 1.5,
        ),
        children: [
          TextSpan(text: 'En continuant, vous acceptez nos '),
          TextSpan(
            text: "Conditions d'utilisation",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
