import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';
import 'edit_trip_screen.dart';
import 'driver_rating_screen.dart';
import '../utils/notification_helper.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _isHoveringBack = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _tripData;
  Map<String, dynamic>? _driverData;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isBooking = false;
  int _driverTotalTrips = 0;

  @override
  void initState() {
    super.initState();
    _fetchTripDetails();
  }

  Future<void> _deleteTrip() async {
    // Confirmation de suppression
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le trajet'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce trajet ?\n\n'
          'Cette action est irréversible et supprimera également toutes les réservations associées.',
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

    if (confirm != true) return;

    setState(() =>
        _isBooking = true); // Réutilisation du flag pour l'état de chargement

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté');
      }

      // Vérifier que l'utilisateur est bien le propriétaire
      if (_tripData!['driverId'] != currentUser.uid) {
        throw Exception('Vous n\'êtes pas autorisé à supprimer ce trajet');
      }

      // Vérifier s'il y a des réservations confirmées
      final bookings = await _firestore
          .collection('bookings')
          .where('tripId', isEqualTo: widget.tripId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      if (bookings.docs.isNotEmpty) {
        throw Exception(
          'Impossible de supprimer un trajet avec des réservations confirmées.\n'
          'Veuillez d\'abord annuler les réservations.',
        );
      }

      // Supprimer toutes les réservations en attente
      final pendingBookings = await _firestore
          .collection('bookings')
          .where('tripId', isEqualTo: widget.tripId)
          .get();

      // Utiliser un batch pour supprimer toutes les réservations
      final batch = _firestore.batch();
      for (var doc in pendingBookings.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer le trajet
      batch.delete(_firestore.collection('trips').doc(widget.tripId));

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trajet supprimé avec succès'),
          backgroundColor: AppColors.success,
        ),
      );

      // Retour à l'écran précédent
      Navigator.pop(context);
    } on Exception catch (e) {
      debugPrint('❌ Erreur de suppression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression du trajet'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  Future<void> _fetchTripDetails() async {
    try {
      DocumentSnapshot tripDoc =
          await _firestore.collection('trips').doc(widget.tripId).get();

      if (!tripDoc.exists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      Map<String, dynamic> tripData = tripDoc.data() as Map<String, dynamic>;
      String driverId = tripData['driverId'] as String? ?? '';

      if (driverId.isNotEmpty) {
        DocumentSnapshot driverDoc =
            await _firestore.collection('users').doc(driverId).get();
        if (driverDoc.exists) {
          _driverData = driverDoc.data() as Map<String, dynamic>;
        }
        final tripsSnapshot = await _firestore
            .collection('trips')
            .where('driverId', isEqualTo: driverId)
            .get();

        _driverTotalTrips = tripsSnapshot.docs.length;
      }

      if (mounted) {
        setState(() {
          _tripData = tripData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des détails du trajet: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _bookTrip(String driverId, double price) async {
    final currentUser = _auth.currentUser!;

    setState(() => _isBooking = true);

    try {
      // Récupérer les données utilisateur DEPUIS FIRESTORE
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('Profil utilisateur introuvable');
      }

      final userData = userDoc.data()!;

      // Récupérer le nom DEPUIS FIRESTORE (pas depuis Auth)
      final userName = userData['name'] as String? ?? 'Utilisateur';
      final userAvatar = userData['avatarUrl'] as String?;

      // Récupérer les infos du conducteur
      final driverDoc =
          await _firestore.collection('users').doc(driverId).get();
      final driverData = driverDoc.exists ? driverDoc.data() : null;
      final driverName = driverData?['name'] as String? ??
          _tripData!['driverName'] as String? ??
          'Conducteur Inconnu';
      final driverAvatar = driverData?['avatarUrl'] as String?;

      debugPrint('🔍 Conducteur: $driverName');

      // ÉTAPE 4 : TRANSACTION ATOMIQUE - UNE SEULE RÉSERVATION
      await _firestore.runTransaction((transaction) async {
        final tripRef = _firestore.collection('trips').doc(widget.tripId);
        final tripSnapshot = await transaction.get(tripRef);

        if (!tripSnapshot.exists) {
          throw Exception('Trajet introuvable');
        }

        final tripData = tripSnapshot.data()!;
        final currentSeats = tripData['availableSeats'] as int? ?? 0;

        if (currentSeats <= 0) {
          throw Exception('Plus de places disponibles');
        }

        // CRÉER UNE SEULE RÉSERVATION AVEC TOUTES LES INFOS
        final bookingRef = _firestore.collection('bookings').doc();
        transaction.set(bookingRef, {
          // Info passager
          'tripId': widget.tripId,
          'passengerId': currentUser.uid,
          'passengerName': userName,
          'passengerAvatar': userAvatar,
          'passengerEmail': userData['email'] ?? currentUser.email,

          // Info conducteur (RÉCUPÉRÉES DEPUIS FIRESTORE)
          'driverId': driverId,
          'driverName': driverName,
          'driverAvatar': driverAvatar,

          // Statut et places
          'status': 'pending',
          'seatsBooked': 1,
          'totalPrice': price,
          'createdAt': FieldValue.serverTimestamp(),

          // Détails du trajet avec prix
          'tripDetails': {
            'from': tripData['departureLocation'],
            'to': tripData['arrivalLocation'],
            'date': tripData['date'],
            'time': tripData['time'] ??
                DateFormat('HH:mm')
                    .format((tripData['date'] as Timestamp).toDate()),
            'price': price, // Prix sauvegardé
          },
        });

        debugPrint('✅ Réservation créée : ${bookingRef.id}');

        // La décrémentation se fera lors de la CONFIRMATION par le conducteur
        transaction.update(tripRef, {
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Créer une notification pour le conducteur
      await NotificationHelper.createBookingNotification(
        driverId: driverId,
        passengerId: currentUser.uid,
        passengerName: userName,
        tripId: widget.tripId,
        from: _tripData!['departureLocation'] as String,
        to: _tripData!['arrivalLocation'] as String,
      );

      if (!mounted) return;

      await _openChat(driverId, userName, isBooking: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation effectuée ! 🎉'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      await _fetchTripDetails();
    } on Exception catch (e) {
      debugPrint('❌ Erreur de réservation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la réservation'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  Future<void> _openChat(String driverId, String userName,
      {required bool isBooking}) async {
    final currentUser = _auth.currentUser!;

    try {
      final conversationId = _generateConversationId(currentUser.uid, driverId);

      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        await _firestore.collection('conversations').doc(conversationId).set({
          'participants': [currentUser.uid, driverId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'unreadCount_${currentUser.uid}': 0,
          'unreadCount_$driverId': 0,
          'tripInfo': {
            'tripId': widget.tripId,
            'from': _tripData!['departureLocation'],
            'to': _tripData!['arrivalLocation'],
          },
        });
      }

      if (isBooking) {
        final messages = [
          "Bonjour ! Je souhaite réserver une place pour ce trajet. 🚗",
          "Salut ! Je suis intéressé(e) par ce trajet. Pouvons-nous discuter des détails ? 😊",
          "Hello ! J'aimerais réserver une place. Êtes-vous disponible pour en discuter ? 🙋",
          "Bonjour ! Ce trajet m'intéresse beaucoup. Je souhaite réserver ! ✨",
        ];
        final randomMessage = (messages..shuffle()).first;

        await _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .add({
          'senderId': currentUser.uid,
          'receiverId': driverId,
          'text': randomMessage,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        await _firestore
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': randomMessage,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUser.uid,
          'unreadCount_$driverId': FieldValue.increment(1),
        });
      }

      final driverDoc =
          await _firestore.collection('users').doc(driverId).get();
      final driverData = driverDoc.data();
      final driverName = driverData?['name'] ?? 'Conducteur';
      final driverAvatar = driverData?['avatarUrl'] as String?;

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserId: driverId,
            otherUserName: driverName,
            otherUserAvatar: driverAvatar,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ouverture du chat'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _generateConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du trajet')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _tripData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du trajet')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger le trajet ou trajet non trouvé.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final String from = _tripData!['departureLocation'] as String? ?? 'N/A';
    final String to = _tripData!['arrivalLocation'] as String? ?? 'N/A';
    final DateTime date = (_tripData!['date'] as Timestamp).toDate();
    final String time =
        _tripData!['time'] as String? ?? DateFormat('HH:mm').format(date);
    final int seats = (_tripData!['availableSeats'] as num?)?.toInt() ?? 0;
    final double price = (_tripData!['price'] as num?)?.toDouble() ?? 0.0;
    final String description =
        _tripData!['description'] as String? ?? 'Aucune description fournie.';
    final Map<String, dynamic> preferencesData =
        _tripData!['preferences'] as Map<String, dynamic>? ?? {};
    final List<String> preferences = _mapPreferencesToList(preferencesData);

    final String driverName = _driverData?['name'] as String? ??
        _tripData!['driverName'] as String? ??
        'Conducteur Inconnu';
    final String? driverAvatar = _driverData?['avatarUrl'] as String?;
    final double driverRating =
        (_driverData?['rating'] as num?)?.toDouble() ?? 0.0;
    final int driverTotalTrips = _driverTotalTrips;

    final String driverBio =
        _driverData?['bio'] as String? ?? 'Bio non disponible.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: MouseRegion(
          onEnter: (_) => setState(() => _isHoveringBack = true),
          onExit: (_) => setState(() => _isHoveringBack = false),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: _isHoveringBack ? AppColors.accent : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Détails du trajet',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDriverCard(driverName, driverAvatar, driverRating,
                      driverTotalTrips, driverBio),
                  const SizedBox(height: 16),
                  _buildItineraryCard(from, to, date, time, seats, price),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(description),
                  const SizedBox(height: 16),
                  _buildOptionsCard(preferences),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomButtons(price),
        ],
      ),
    );
  }

  List<String> _mapPreferencesToList(Map<String, dynamic> preferencesData) {
    List<String> result = [];
    preferencesData.forEach((key, value) {
      if (value is String && value.isNotEmpty && value != 'N/A') {
        result.add(
            '${key.substring(0, 1).toUpperCase()}${key.substring(1)}: $value');
      } else if (value is bool && value) {
        result.add(key);
      }
    });
    return result;
  }

  Widget _buildDriverCard(
      String name, String? avatarUrl, double rating, int trips, String bio) {
    final gender = _driverData?['gender'] as String?;
    final hasLicense = _driverData?['hasDriverLicense'] as bool? ?? false;
    final phoneNumber = _driverData?['phone'] as String?;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partie supérieure (avatar + infos)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (gender != null && gender != 'Non spécifié') ...[
                          const SizedBox(width: 6),
                          Icon(
                            gender == 'Homme' ? Icons.male : Icons.female,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : 'Non noté',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· $trips trajets',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (hasLicense) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Permis',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Affichage du numéro de téléphone
          if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Téléphone',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],

          // ✅ NOUVEAU : Bouton pour noter le conducteur
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverRatingScreen(
                      driverId: _tripData!['driverId'] as String,
                      driverName: name,
                      driverAvatar: avatarUrl,
                    ),
                  ),
                );

                // Si une note a été ajoutée, recharger les détails
                if (result == true && mounted) {
                  _fetchTripDetails();
                }
              },
              icon: const Icon(Icons.star_outline, size: 18),
              label: const Text('Évaluer ce conducteur'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side:
                    BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                foregroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(String from, String to, DateTime date, String time,
      int seats, double price) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Itinéraire',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 60,
                    color: AppColors.textMuted,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      to,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildInfoIcon(
                  Icons.calendar_today, DateFormat('dd MMM yyyy').format(date)),
              const SizedBox(width: 20),
              _buildInfoIcon(Icons.people_outline, '$seats places'),
              const Spacer(),
              Text(
                '${price.toInt()} TND',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
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

  Widget _buildOptionsCard(List<String> preferences) {
    if (preferences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                preferences.map((pref) => _buildOptionChip(pref)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.accent,
        ),
      ),
    );
  }

  Widget _buildBottomButtons(double price) {
    final currentUser = _auth.currentUser!;
    final driverId = _tripData!['driverId'] as String;
    final isMyOwnTrip = currentUser.uid == driverId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: isMyOwnTrip
            ? _buildOwnTripButton()
            : _buildPassengerButtons(price, driverId),
      ),
    );
  }

  Widget _buildOwnTripButton() {
    return Column(
      children: [
        // Bouton Modifier (existant)
        SizedBox(
          width: double.infinity,
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
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTripScreen(
                      tripId: widget.tripId,
                      tripData: _tripData!,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  _fetchTripDetails();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Modifier le trajet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Nouveau bouton Supprimer
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isBooking ? null : _deleteTrip,
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Supprimer le trajet'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerButtons(double price, String driverId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .get();
              final userName = userDoc.data()?['name'] ?? 'Utilisateur';

              if (!mounted) return;
              _openChat(driverId, userName, isBooking: false);
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.accent),
              foregroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
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
              onPressed: _isBooking ? null : () => _bookTrip(driverId, price),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Réserver (${price.toInt()} TND)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
