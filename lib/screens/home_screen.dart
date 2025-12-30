import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importer FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Importer Cloud Firestore
import '../widgets/bottom_nav.dart';
import '../utils/constants.dart';
import 'auth_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  User? _currentUser; // Pour stocker les informations de l'utilisateur Firebase

  // Instance de Firestore pour récupérer les trajets
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Liste pour stocker les trajets populaires (exemple)
  List<DocumentSnapshot> _popularTrips = [];
  bool _isLoadingTrips = true; // Pour gérer l'état de chargement des trajets

  @override
  void initState() {
    super.initState();
    _checkCurrentUser(); // Vérifie l'utilisateur actuel au démarrage de l'écran
    _fetchPopularTrips(); // Charge les trajets populaires
  }

  void _checkCurrentUser() {
    // Écoute les changements d'état d'authentification
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        if (user == null) {
          // Si l'utilisateur se déconnecte, redirige vers l'écran d'authentification
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      }
    });
  }

  void _fetchPopularTrips() async {
    try {
      // Récupère les 5 trajets les plus populaires (vous devrez définir la logique de "popularité" dans Firestore)
      // Par exemple, en triant par un champ 'vues' ou 'likes'
      QuerySnapshot querySnapshot = await _firestore
          .collection('trips') // Supposons une collection 'trips'
          .orderBy('popularityScore',
              descending: true) // Trie par un score de popularité
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          _popularTrips = querySnapshot.docs;
          _isLoadingTrips = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des trajets populaires : $e');
      if (mounted) {
        setState(() {
          _isLoadingTrips = false;
        });
      }
      // Optionnel: afficher un message d'erreur à l'utilisateur
      _showSnackBar('Impossible de charger les trajets. Veuillez réessayer.');
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // TODO: Navigation vers les autres écrans
    switch (index) {
      case 0:
        // Déjà sur Home
        break;
      case 1:
        debugPrint('Navigation vers Recherche');
        // Exemple de déconnexion pour le test (peut être déplacé ailleurs)
        // FirebaseAuth.instance.signOut();
        break;
      case 2:
        debugPrint('Navigation vers Publier');
        break;
      case 3:
        debugPrint('Navigation vers Messages');
        break;
      case 4:
        debugPrint('Navigation vers Profil');
        break;
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header avec dégradé
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre avec logo et nom d'utilisateur
                          _buildHeader(),

                          const SizedBox(height: 24),

                          // Barre de recherche
                          _buildSearchBar(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Features (Économique, Sécurisé, Écologique)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pourquoi CoRide ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.savings_outlined,
                            title: 'Économique',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.shield_outlined,
                            title: 'Sécurisé',
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.eco_outlined,
                            title: 'Écologique',
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Section Trajets populaires
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trajets populaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.accent.withOpacity(0.1), // Correction ici
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Aujourd'hui",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contenu des trajets populaires ou état vide
            _isLoadingTrips
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _popularTrips.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Afficher chaque trajet populaire ici
                            // Remplacez par votre widget de carte de trajet
                            return _buildTripCard(_popularTrips[index]);
                          },
                          childCount: _popularTrips.length,
                        ),
                      ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // Header avec logo, nom d'utilisateur et notifications
  Widget _buildHeader() {
    return Row(
      children: [
        // Logo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.directions_car,
                color: AppColors.primary,
                size: 24,
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // Titre + Nom d'utilisateur
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tunisia CoRide',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _currentUser != null
                  ? Text(
                      'Bienvenue, ${_currentUser!.displayName ?? _currentUser!.email?.split('@')[0] ?? 'Utilisateur'} !',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    )
                  : const Text(
                      'Connecting your journeys',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
            ],
          ),
        ),

        // Bouton notifications
        IconButton(
          onPressed: () {
            debugPrint('Notifications');
            // Optionnel: Déconnexion pour les tests
            // FirebaseAuth.instance.signOut();
          },
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  // Barre de recherche
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Correction ici
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
            debugPrint('Navigation vers Recherche');
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Où allez-vous ?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card feature
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), // Correction ici
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher un trajet (à adapter)
  Widget _buildTripCard(DocumentSnapshot trip) {
    // Remplacez ceci par votre véritable design de carte de trajet
    Map<String, dynamic> data = trip.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Départ: ${data['departureLocation'] ?? 'N/A'}'),
            Text('Arrivée: ${data['arrivalLocation'] ?? 'N/A'}'),
            Text('Date: ${data['date']?.toDate() ?? 'N/A'}'),
            Text('Prix: ${data['price'] ?? 'N/A'} DT'),
            // Ajoutez d'autres champs si nécessaire
          ],
        ),
      ),
    );
  }

  // État vide (pas encore de trajets)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // Correction ici
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 60,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Titre
            const Text(
              'Aucun trajet disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Les trajets seront chargés\n',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Bouton Publier
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigation vers PublishRideScreen
                debugPrint('Navigation vers Publier un trajet');
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Publier un trajet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
