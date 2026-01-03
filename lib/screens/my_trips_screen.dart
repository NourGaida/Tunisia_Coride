import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import 'publish_ride_screen.dart';
import 'trip_detail_screen.dart';
import '../utils/notification_helper.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 3 Onglets : À venir, Historique, Demandes
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
      return const Scaffold(
        body: Center(child: Text("Veuillez vous connecter")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mes Trajets',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Historique'),
            // Nouvel onglet avec potentiellement un Badge pour les notifs (optionnel)
            Tab(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Demandes'),
                SizedBox(width: 4),
                Icon(Icons.notifications_active_outlined, size: 16),
              ],
            )),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList('upcoming', currentUser.uid),
          _buildTripList('completed', currentUser.uid),
          _buildIncomingRequests(currentUser.uid), // <--- NOUVELLE FONCTION
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LISTES EXISTANTES (À venir / Historique)
  // ---------------------------------------------------------------------------
  Widget _buildTripList(String status, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('trips')
          .where('driverId', isEqualTo: uid)
          .where('status', isEqualTo: status)
          .orderBy('date', descending: status == 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDetailScreen(tripId: doc.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEE d MMM, HH:mm', 'fr_FR')
                                .format(date),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'upcoming'
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status == 'upcoming' ? 'En ligne' : 'Terminé',
                              style: TextStyle(
                                color: status == 'upcoming'
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF4B5563),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.circle_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['departureLocation'] ?? 'Départ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Container(
                          height: 20,
                          width: 2,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['arrivalLocation'] ?? 'Arrivée',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.airline_seat_recline_normal,
                                  size: 16, color: Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Text(
                                // ✅ OPTION 2 : Afficher seulement les places disponibles
                                '${data['availableSeats']} place${data['availableSeats'] > 1 ? 's' : ''} disponible${data['availableSeats'] > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${data['price']} TND',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // NOUVELLE FONCTION : GESTION DES DEMANDES REÇUES
  // ---------------------------------------------------------------------------
  Widget _buildIncomingRequests(String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('driverId', isEqualTo: driverId)
          .where('status',
              isEqualTo: 'pending') // Seulement les demandes en attente
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      size: 50, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Aucune demande en attente",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final tripDetails = data['tripDetails'] ?? {};

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  // En-tête : Info trajet
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${tripDetails['from'] ?? '?'} → ${tripDetails['to'] ?? '?'}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(tripDetails['date']),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Corps : Info Passager
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppColors.accent.withValues(alpha: 0.1),
                          backgroundImage: data['passengerAvatar'] != null
                              ? NetworkImage(data['passengerAvatar'])
                              : null,
                          child: data['passengerAvatar'] == null
                              ? const Icon(Icons.person,
                                  color: AppColors.accent)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['passengerName'] ?? 'Utilisateur',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.airline_seat_recline_normal,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    "1 place demandée",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Pied : Actions (Accepter / Refuser)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _handleRequest(doc.id, false, null),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Refuser"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _handleRequest(doc.id, true, data['tripId']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Accepter",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper pour formater la date
  String _formatDate(dynamic dateData) {
    if (dateData == null) return "";
    if (dateData is Timestamp) {
      return DateFormat('dd MMM, HH:mm', 'fr_FR').format(dateData.toDate());
    }
    return "";
  }

  // ---------------------------------------------------------------------------
  // LOGIQUE DE TRAITEMENT (Accepter / Refuser)
  // ---------------------------------------------------------------------------
  Future<void> _handleRequest(
      String bookingId, bool isAccepted, String? tripId) async {
    try {
      if (isAccepted && tripId != null) {
        // 1. Vérifier la disponibilité
        final tripRef = _firestore.collection('trips').doc(tripId);
        final tripSnapshot = await tripRef.get();

        if (!tripSnapshot.exists) {
          _showSnack("Erreur : Trajet introuvable", isError: true);
          return;
        }

        final currentSeats = tripSnapshot.data()?['availableSeats'] ?? 0;
        if (currentSeats <= 0) {
          _showSnack("Plus de places disponibles !", isError: true);
          return;
        }

        await _firestore.collection('bookings').doc(bookingId).update({
          'status': 'confirmed',
        });

        // Décrémenter les places
        await tripRef.update({
          'availableSeats': FieldValue.increment(-1),
        });

        final bookingDoc =
            await _firestore.collection('bookings').doc(bookingId).get();
        final bookingData = bookingDoc.data();
        final driverDoc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();
        final driverName = driverDoc.data()?['name'] as String? ?? 'Conducteur';

        await NotificationHelper.createBookingConfirmedNotification(
          passengerId: bookingData?['passengerId'] as String,
          driverName: driverName,
          tripId: tripId,
          from: bookingData?['tripDetails']['from'] as String? ?? '',
          to: bookingData?['tripDetails']['to'] as String? ?? '',
        );

        _showSnack("Demande acceptée avec succès !", isError: false);
      } else {
        // REFUSER
        await _firestore.collection('bookings').doc(bookingId).update({
          'status': 'rejected',
        });

        final bookingDoc =
            await _firestore.collection('bookings').doc(bookingId).get();
        final bookingData = bookingDoc.data();
        final driverDoc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();
        final driverName = driverDoc.data()?['name'] as String? ?? 'Conducteur';

        await NotificationHelper.createBookingRejectedNotification(
          passengerId: bookingData?['passengerId'] as String,
          driverName: driverName,
          tripId: tripId ?? '',
          from: bookingData?['tripDetails']['from'] as String? ?? '',
          to: bookingData?['tripDetails']['to'] as String? ?? '',
        );

        _showSnack("Demande refusée.", isError: false);
      }
    } catch (e) {
      debugPrint("Erreur handleRequest: $e");
      _showSnack("Une erreur est survenue", isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET EMPTY STATE (Votre code existant)
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(String status) {
    final isUpcoming = status == 'upcoming';
    final icon = isUpcoming ? Icons.directions_car_outlined : Icons.history;
    final message = isUpcoming
        ? 'Vous n\'avez pas encore publié de trajet à venir'
        : 'Aucun trajet terminé dans l\'historique';

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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PublishRideScreen()));
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
          ],
        ),
      ),
    );
  }
}
