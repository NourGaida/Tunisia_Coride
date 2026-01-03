import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav.dart';
import 'auth_screen.dart';
import 'my_trips_screen.dart';
import 'my_bookings_screen.dart';
import 'search_screen.dart';
import 'publish_ride_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';
import 'payment_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 4;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // ✅ Données dynamiques
  int _totalTrips = 0;
  int _totalPassengers = 0;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = _auth.currentUser;

    if (_currentUser != null) {
      try {
        // 1. Charger les données utilisateur
        final doc =
            await _firestore.collection('users').doc(_currentUser!.uid).get();

        if (mounted) {
          setState(() {
            _userData = doc.data();
          });
        }

        // 2. ✅ Calculer les statistiques dynamiques
        await _calculateStatistics();

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Erreur chargement profil: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // ========================================================================
  // ✅ CALCUL DES STATISTIQUES DYNAMIQUES
  // ========================================================================
  Future<void> _calculateStatistics() async {
    if (_currentUser == null) return;

    try {
      // 1. Nombre total de trajets publiés
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: _currentUser!.uid)
          .get();

      _totalTrips = tripsSnapshot.docs.length;

      // 2. Nombre total de passagers (réservations confirmées)
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('driverId', isEqualTo: _currentUser!.uid)
          .where('status', isEqualTo: 'confirmed')
          .get();

      // Compter le nombre de places réservées (seatsBooked)
      int passengersCount = 0;
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        passengersCount += (data['seatsBooked'] as int? ?? 1);
      }
      _totalPassengers = passengersCount;

      // 3. Note moyenne et nombre total de notes
      final ratingsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('ratings')
          .get();

      final totalRatings = ratingsSnapshot.docs.length;

      if (totalRatings > 0) {
        double totalRating = 0.0;
        for (var doc in ratingsSnapshot.docs) {
          final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
          totalRating += rating;
        }
        _averageRating = totalRating / totalRatings;
      } else {
        _averageRating = 0.0;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Erreur calcul statistiques: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {},
        ),
      );
    }

    final userName = _userData?['name'] ??
        _currentUser?.displayName ??
        _currentUser?.email?.split('@')[0] ??
        'Utilisateur';
    final userEmail = _userData?['email'] ?? _currentUser?.email ?? '';
    final userPhone = _userData?['phone'] ?? '';
    final memberSince =
        (_userData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    // ✅ Bio dynamique
    final userBio = _userData?['bio'] as String? ??
        'Aucune description disponible pour le moment.';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          _buildHeader(userName, memberSince),
          _buildDraggableSheet(userName, userEmail, userPhone, userBio),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;

          setState(() => _currentIndex = index);

          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PublishRideScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              );
              break;
            case 4:
              break;
          }
        },
      ),
    );
  }

  Widget _buildHeader(String userName, DateTime memberSince) {
    final avatarUrl = _userData?['avatarUrl'] as String?;

    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(userName);
                      },
                    ),
                  )
                : _buildDefaultAvatar(userName),
          ),

          const SizedBox(height: 16),

          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Membre depuis ${memberSince.year}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 8),

          // ✅ Note dynamique
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($_totalTrips trajet${_totalTrips > 1 ? 's' : ''})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String userName) {
    return Center(
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDraggableSheet(
      String userName, String userEmail, String userPhone, String userBio) {
    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.60,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Stats dynamiques
              _buildStats(),

              const SizedBox(height: 16),

              // ✅ Bio dynamique
              _buildAboutCard(userBio),

              const SizedBox(height: 16),

              _buildVerificationsCard(userEmail, userPhone),

              const SizedBox(height: 16),

              _buildMenuCard(),

              const SizedBox(height: 16),

              _buildLogoutButton(),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // ✅ Stats dynamiques
  Widget _buildStats() {
    return Row(
      children: [
        _buildStatCard(
          Icons.directions_car_outlined,
          _totalTrips.toString(),
          'Trajet${_totalTrips > 1 ? 's' : ''}',
          AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          Icons.people_outline,
          _totalPassengers.toString(),
          'Passager${_totalPassengers > 1 ? 's' : ''}',
          AppColors.accent,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          Icons.star_outline,
          _averageRating.toStringAsFixed(1),
          'Note',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Bio dynamique
  Widget _buildAboutCard(String userBio) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userBio,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationsCard(String userEmail, String userPhone) {
    final hasDriverLicense = _userData?['hasDriverLicense'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vérifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildVerificationRow('Numéro de téléphone', userPhone.isNotEmpty),
          const Divider(height: 24),
          _buildVerificationRow('Email', userEmail.isNotEmpty),
          const Divider(height: 24),
          _buildVerificationRow('Permis de conduire', hasDriverLicense),
        ],
      ),
    );
  }

  Widget _buildVerificationRow(String label, bool isVerified) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (isVerified)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vérifié',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
            ],
          )
        else
          const Text(
            'Non vérifié',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.directions_car_outlined,
            title: 'Mes trajets',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyTripsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(
            icon: Icons.bookmark_outline,
            title: 'Mes réservations',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBookingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(
            icon: Icons.payment_outlined,
            title: 'Mode de paiement',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Paramètres',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );

              if (result == true) {
                _loadUserData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Se déconnecter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
