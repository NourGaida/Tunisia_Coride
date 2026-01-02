import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav.dart';
import '../utils/constants.dart';
import 'auth_screen.dart';
import 'search_screen.dart';
import 'publish_ride_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'trip_detail_screen.dart';
import '../models/ride.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  User? _currentUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Ride> _popularTrips = []; // <<< MODIFIÉ : Stocke des objets Ride
  bool _isLoadingTrips = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _fetchPopularTrips();
  }

  void _checkCurrentUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        if (user == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      }
    });
  }

  void _fetchPopularTrips() async {
    try {
      // Filtrer pour n'afficher que les trajets 'upcoming'
      // et ceux dont la date est supérieure ou égale à aujourd'hui
      QuerySnapshot querySnapshot = await _firestore
          .collection('trips')
          .where('status',
              isEqualTo:
                  'upcoming') // Assurez-vous que le statut est 'upcoming'
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('popularityScore', descending: true)
          .orderBy('date',
              descending:
                  false) // Ajouter un ordre par date si popularityScore est le même
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          // Convertit chaque DocumentSnapshot en objet Ride
          _popularTrips =
              querySnapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList();
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
      _showSnackBar('Impossible de charger les trajets. Veuillez réessayer.');
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Déjà sur Home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ).then((_) {
          // Réinitialiser _currentIndex si l'utilisateur revient à Home via le bouton retour de l'AppBar de SearchScreen
          // ou gérer l'état global de navigation si vous utilisez un système de routing plus avancé
          setState(() {
            _currentIndex = 0;
          });
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PublishRideScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        ).then((_) {
          // Réinitialiser _currentIndex si l'utilisateur revient à Home via le bouton retour de l'AppBar de ProfileScreen
          setState(() {
            _currentIndex = 0;
          });
        });
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
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                    ],
                  ),
                ),
              ),
            ),
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
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent
                            .withValues(alpha: 0.1), // Rétabli withValues
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
            _isLoadingTrips
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : _popularTrips.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          // On passe l'objet Ride complet à _buildTripCard
                          (context, index) =>
                              _buildTripCard(_popularTrips[index]),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.directions_car,
                  color: AppColors.primary, size: 24);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tunisia CoRide',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              _currentUser != null
                  ? Text(
                      'Bienvenue, ${_currentUser!.displayName ?? _currentUser!.email?.split('@')[0] ?? 'Utilisateur'} !',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70),
                    )
                  : const Text(
                      'Connecting your journeys',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => debugPrint('Notifications'),
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // Rétabli withValues
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textMuted, size: 24),
                SizedBox(width: 12),
                Text(
                  'Où allez-vous ?',
                  style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      {required IconData icon, required String title, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), // Rétabli withValues
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
        ],
      ),
    );
  }

  // <<< MODIFIÉ : _buildTripCard accepte un objet Ride
  Widget _buildTripCard(Ride ride) {
    // Utilise les propriétés de l'objet Ride directement
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        // Ajouté InkWell pour le onTap
        onTap: () {
          // Navigue vers TripDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailScreen(
                tripId: ride.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8), // Rayon pour le InkWell
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Départ: ${ride.from}'),
              Text('Arrivée: ${ride.to}'),
              Text(
                  'Date: ${DateFormat('dd MMM').format(ride.date)}'), // Utilise DateFormat pour la date
              Text('Prix: ${ride.price.toInt()} DT'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.1), // Rétabli withValues
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off,
                  size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun trajet disponible',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Les trajets seront chargés\n',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PublishRideScreen())),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Publier un trajet'),
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
