import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchTripDetails();
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
    final int driverTotalTrips = (_driverData?['trips'] as num?)?.toInt() ?? 0;
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
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
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
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
                    decoration: BoxDecoration(
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted),
      ),
      child: const Text(
        'Votre trajet',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPassengerButtons(double price, String driverId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openChat(driverId, isBooking: false),
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

  Future<void> _openChat(String driverId, {required bool isBooking}) async {
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

  Future<void> _bookTrip(String driverId, double price) async {
    final currentUser = _auth.currentUser!;

    setState(() => _isBooking = true);

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final userName =
          userData?['name'] ?? currentUser.email?.split('@')[0] ?? 'Passager';

      await _firestore.collection('bookings').add({
        'tripId': widget.tripId,
        'passengerId': currentUser.uid,
        'passengerName': userName,
        'driverId': driverId,
        'status': 'pending',
        'seatsBooked': 1,
        'totalPrice': price,
        'createdAt': FieldValue.serverTimestamp(),
        'tripDetails': {
          'from': _tripData!['departureLocation'],
          'to': _tripData!['arrivalLocation'],
          'date': _tripData!['date'],
        },
      });

      await _firestore.collection('trips').doc(widget.tripId).update({
        'availableSeats': FieldValue.increment(-1),
      });

      if (!mounted) return;

      await _openChat(driverId, isBooking: true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation effectuée ! 🎉'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de la réservation: $e');
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

  String _generateConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}
