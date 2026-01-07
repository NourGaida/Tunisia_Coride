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
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  User? _currentUser;
  String? _userName;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Ride> _popularTrips = []; // <<< Stocke des objets Ride
  bool _isLoadingTrips = true;
  int _unreadNotificationsCount = 0;
  
  // Pour gérer le hover effect sur les cartes
  final Map<String, bool> _hoveredCards = {};

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _fetchPopularTrips();
  }

  void _checkCurrentUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        if (user == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        } else {
          // Récupérer le nom depuis Firestore
          try {
            final userDoc =
                await _firestore.collection('users').doc(user.uid).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              if (mounted) {
                setState(() {
                  _userName = userData?['name'] as String?;
                });
              }
            }
          } catch (e) {
            debugPrint('Erreur récupération nom: $e');
          }

          // NOUVEAU : Écouter les notifications
          _listenToNotifications();
        }
      }
    });
  }

  void _listenToNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = snapshot.docs.length;
        });
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
                  gradient: AppColors.headerGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
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
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.2,
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
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.2,
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
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.2),
          ),
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.directions_car,
                  color: Colors.white, size: 26);
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CoRide',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5),
              ),
              // ✅ MODIFIÉ : Afficher le nom récupéré de Firestore
              _currentUser != null
                  ? Text(
                      'Connecting your journeys',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : Text(
                      'Connecting your journeys',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
            ],
          ),
        ),
        // ✅ MODIFIÉ : Bouton notifications avec badge
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
            ),
            if (_unreadNotificationsCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      _unreadNotificationsCount > 9
                          ? '9+'
                          : _unreadNotificationsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.primary.withValues(alpha: 0.6), size: 22),
                const SizedBox(width: 12),
                const Text(
                  'Où allez-vous ?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB0B8C1),
                    fontWeight: FontWeight.w400,
                  ),
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
    final key = 'feature_${title.replaceAll(' ', '_').toLowerCase()}';
    final isHovered = _hoveredCards[key] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCards[key] = true),
      onExit: (_) => setState(() => _hoveredCards[key] = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _hoveredCards[key] = true),
        onTapUp: (_) => setState(() => _hoveredCards[key] = false),
        onTapCancel: () => setState(() => _hoveredCards[key] = false),
        child: AnimatedScale(
          scale: isHovered ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7EAF0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isHovered ? 0.10 : 0.03),
                  blurRadius: isHovered ? 18 : 8,
                  offset: isHovered ? const Offset(0, 8) : const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // <<<  _buildTripCard accepte un objet Ride
  Widget _buildTripCard(Ride ride) {
    // Utilise les propriétés de l'objet Ride directement
    final isHovered = _hoveredCards[ride.id] ?? false;
    
  return MouseRegion(
    onEnter: (_) {
      setState(() {
        _hoveredCards[ride.id] = true;
      });
    },
    onExit: (_) {
      setState(() {
        _hoveredCards[ride.id] = false;
      });
    },
    child: AnimatedScale(
      scale: isHovered ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isHovered ? 0.20 : 0.06),
              blurRadius: isHovered ? 20 : 12,
              offset: isHovered ? const Offset(0, 6) : const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
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
          onTapDown: (_) {
            setState(() {
              _hoveredCards[ride.id] = true;
            });
          },
          onTapUp: (_) {
            setState(() {
              _hoveredCards[ride.id] = false;
            });
          },
          onTapCancel: () {
            setState(() {
              _hoveredCards[ride.id] = false;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section conducteur avec photo et note
                Row(
                  children: [
                    // Photo du conducteur
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ride.driver.avatar != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              ride.driver.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Nom et note
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.driver.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFCD34D),
                              size: 17,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${ride.driver.rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${ride.driver.trips} trajets',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Lieux de départ et arrivée
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 20,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ride.from,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          ride.to,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Informations du trajet (date, heure, places)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM').format(ride.date),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ride.time,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${ride.availableSeats} places',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Séparateur
              Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 12),
              // Prix et bouton disponible
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ride.price.toInt()} TND',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Text(
                        '/ personne',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'Disponible',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
