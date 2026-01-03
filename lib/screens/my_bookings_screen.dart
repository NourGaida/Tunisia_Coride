import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../widgets/booking_card.dart';
import 'trip_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Connectez-vous")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Mes Réservations',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Historique'),
            Tab(text: 'Refusés'), // ✅ NOUVEL ONGLET
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1 : En cours (pending + confirmed dont date >= aujourd'hui)
          _buildOngoingBookings(currentUser.uid),

          // Onglet 2 : Historique (completed + trajets passés)
          _buildHistoryBookings(currentUser.uid),

          // Onglet 3 : Refusés
          _buildRejectedBookings(currentUser.uid),
        ],
      ),
    );
  }

  // ========================================================================
  // ONGLET 1 : RÉSERVATIONS EN COURS
  // Critères : (status = pending OU confirmed) ET date >= aujourd'hui
  // ========================================================================
  Widget _buildOngoingBookings(String userId) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('passengerId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_available,
            message: 'Aucune réservation en cours',
          );
        }

        // Filtrer : garder seulement les trajets dont la date >= aujourd'hui
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final tripDetails = data['tripDetails'] as Map<String, dynamic>?;
          if (tripDetails == null || tripDetails['date'] == null) return false;

          final tripDate = (tripDetails['date'] as Timestamp).toDate();
          return tripDate.isAfter(startOfToday) ||
              tripDate.isAtSameMomentAs(startOfToday);
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_available,
            message: 'Aucune réservation en cours',
          );
        }

        return _buildBookingsList(docs);
      },
    );
  }

  // ========================================================================
  // ONGLET 2 : HISTORIQUE
  // Critères : (status = completed) OU (date < aujourd'hui)
  // ========================================================================
  Widget _buildHistoryBookings(String userId) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('passengerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            message: 'Aucun trajet dans l\'historique',
          );
        }

        // Filtrer : completed OU date passée (exclure rejected)
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;

          // Exclure les refusés
          if (status == 'rejected') return false;

          // Inclure les completed
          if (status == 'completed') return true;

          // Inclure si date < aujourd'hui
          final tripDetails = data['tripDetails'] as Map<String, dynamic>?;
          if (tripDetails == null || tripDetails['date'] == null) return false;

          final tripDate = (tripDetails['date'] as Timestamp).toDate();
          return tripDate.isBefore(startOfToday);
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            message: 'Aucun trajet dans l\'historique',
          );
        }

        return _buildBookingsList(docs);
      },
    );
  }

  // ========================================================================
  // ONGLET 3 : RÉSERVATIONS REFUSÉES
  // ========================================================================
  Widget _buildRejectedBookings(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('passengerId', isEqualTo: userId)
          .where('status', isEqualTo: 'rejected')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            message: 'Aucune réservation refusée',
            subtitle: 'Tant mieux ! 😊',
          );
        }

        return _buildBookingsList(snapshot.data!.docs);
      },
    );
  }

  // ========================================================================
  // LISTE DES RÉSERVATIONS AVEC BOOKING CARD
  // ========================================================================
  Widget _buildBookingsList(List<QueryDocumentSnapshot> docs) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final tripId = data['tripId'] as String?;

        // Utiliser le nouveau BookingCard
        return BookingCard(
          bookingData: data,
          onTap: tripId != null && tripId.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripDetailScreen(tripId: tripId),
                    ),
                  );
                }
              : () {},
        );
      },
    );
  }

  // ========================================================================
  // WIDGETS AUXILIAIRES
  // ========================================================================
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Impossible de charger les réservations.\nVérifiez votre connexion.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
