import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../widgets/ride_card.dart';
import '../widgets/bottom_nav.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Données mockées
  final List<Ride> _mockRides = [
    Ride(
      id: '1',
      driver: Driver(
        name: 'Salim Ben Youssef',
        avatar: '',
        rating: 4.8,
        trips: 45,
        bio: 'Étudiant en IT à Sousse',
      ),
      from: 'Sousse - Centre Ville',
      to: 'Tunis - Lac 2',
      date: '16 Nov',
      time: '08:00',
      price: 15,
      seats: 3,
      description: 'Trajet direct par autoroute',
    ),
    Ride(
      id: '2',
      driver: Driver(
        name: 'Lilia Ben Yahia',
        avatar: '',
        rating: 4.9,
        trips: 156,
        bio: 'Employée dans une entreprise privée',
      ),
      from: 'Ariana - Centre',
      to: 'Tunis - Centre Ville',
      date: '15 Nov',
      time: '07:30',
      price: 5,
      seats: 2,
      description: 'Trajet quotidien vers le centre-ville',
    ),
    Ride(
      id: '3',
      driver: Driver(
        name: 'Salim Ben Youssef',
        avatar: '',
        rating: 4.8,
        trips: 45,
        bio: 'Étudiant en IT',
      ),
      from: 'Tunis - Gare',
      to: 'Sousse - Port',
      date: '17 Nov',
      time: '17:00',
      price: 18,
      seats: 4,
      description: 'Retour vers Sousse en fin d\'après-midi',
    ),
  ];

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

  void _onRideTap(Ride ride) {
    // TODO: Navigation vers détail du trajet
    debugPrint('Clic sur trajet: ${ride.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
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
                          // Titre
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tunisia CoRide',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Connecting your journeys',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),

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

            // Trajets populaires
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
                        color: AppColors.accent.withValues(alpha: 0.1),
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

            // Liste des trajets
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RideCard(
                        ride: _mockRides[index],
                        onTap: () => _onRideTap(_mockRides[index]),
                      ),
                    );
                  },
                  childCount: _mockRides.length,
                ),
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

  // Barre de recherche
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigation vers SearchScreen
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
              color: color.withValues(alpha: 0.1),
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
}
