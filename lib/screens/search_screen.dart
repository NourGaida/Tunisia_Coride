import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../widgets/ride_card.dart';
import '../utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _hasSearched = false;

  // Données mockées pour la démo (seront remplacées par Firebase)
  final List<Ride> _mockResults = [
    Ride(
      id: '1',
      driver: Driver(
        name: 'Salim Ben Youssef',
        avatar: '',
        rating: 4.8,
        trips: 45,
        bio: 'Étudiant en IT',
      ),
      from: 'Sousse - Centre Ville',
      to: 'Tunis - Lac 2',
      date: '16 Nov',
      time: '08:00',
      price: 15,
      seats: 3,
      description: 'Trajet direct',
    ),
    Ride(
      id: '2',
      driver: Driver(
        name: 'Lilia Ben Yahia',
        avatar: '',
        rating: 4.9,
        trips: 156,
        bio: 'Employée',
      ),
      from: 'Ariana - Centre',
      to: 'Tunis - Centre Ville',
      date: '15 Nov',
      time: '07:30',
      price: 5,
      seats: 2,
      description: 'Trajet quotidien',
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
      description: 'Retour Sousse',
    ),
  ];

  List<Ride> _searchResults = [];

  void _performSearch() {
    setState(() {
      _hasSearched = true;
      // TODO: Implémenter la vraie recherche avec Firebase
      // Pour l'instant, retourner tous les résultats mockés
      _searchResults = _mockResults;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: const Text(
          'Rechercher un trajet',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Formulaire de recherche
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Départ
                _buildSearchField(
                  controller: _fromController,
                  icon: Icons.location_on,
                  iconColor: AppColors.primary,
                  hint: 'Départ (ex: Tunis)',
                ),

                const SizedBox(height: 12),

                // Arrivée
                _buildSearchField(
                  controller: _toController,
                  icon: Icons.location_on,
                  iconColor: AppColors.accent,
                  hint: 'Arrivée (ex: Sousse)',
                ),

                const SizedBox(height: 12),

                // Date
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bouton Rechercher
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rechercher un trajet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Résultats
          Expanded(
            child: _hasSearched
                ? _searchResults.isEmpty
                    ? _buildEmptyResults()
                    : _buildResultsList()
                : _buildInitialState(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Recherchez votre trajet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun trajet trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres critères',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      children: [
        // Header avec nombre de résultats
        Container(
          padding: const EdgeInsets.all(20),
          color: const Color(0xFFF9FAFB),
          child: Row(
            children: [
              const Text(
                'Trajets disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${_searchResults.length} trajet${_searchResults.length > 1 ? 's' : ''} trouvé${_searchResults.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),

        // Liste des trajets
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return RideCard(
                ride: _searchResults[index],
                onTap: () {
                  // TODO: Navigation vers détail du trajet
                  debugPrint('Trajet sélectionné: ${_searchResults[index].id}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
}
