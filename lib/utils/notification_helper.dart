import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification de nouveau message
  static Future<void> createMessageNotification({
    required String userId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String conversationId,
    required String messagePreview,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'message',
        'title': 'Nouveau message',
        'message': '$senderName: $messagePreview',
        'data': {
          'conversationId': conversationId,
          'senderId': senderId,
          'senderName': senderName,
          'senderAvatar': senderAvatar,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur création notification message: $e');
    }
  }

  // Notification d'évaluation
  static Future<void> createRatingNotification({
    required String userId,
    required String raterId,
    required String raterName,
    required double rating,
    String? comment,
  }) async {
    try {
      String message =
          '$raterName vous a attribué une note de ${rating.toStringAsFixed(1)} ⭐';
      if (comment != null && comment.isNotEmpty) {
        message += '\n"$comment"';
      }

      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'rating',
        'title': 'Nouvelle évaluation',
        'message': message,
        'data': {
          'raterId': raterId,
          'raterName': raterName,
          'rating': rating,
          'comment': comment ?? '',
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur création notification évaluation: $e');
    }
  }

  // Notification de nouvelle réservation (pour le conducteur)
  static Future<void> createBookingNotification({
    required String driverId,
    required String passengerId,
    required String passengerName,
    required String tripId,
    required String from,
    required String to,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': driverId,
        'type': 'booking',
        'title': '🎉 Nouvelle réservation !',
        'message':
            '$passengerName souhaite réserver votre trajet de $from à $to',
        'data': {
          'tripId': tripId,
          'passengerId': passengerId,
          'passengerName': passengerName,
          'from': from,
          'to': to,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur création notification réservation: $e');
    }
  }

  // Notification de réservation confirmée (pour le passager)
  static Future<void> createBookingConfirmedNotification({
    required String passengerId,
    required String driverName,
    required String tripId,
    required String from,
    required String to,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': passengerId,
        'type': 'booking_confirmed',
        'title': '✅ Réservation confirmée',
        'message':
            '$driverName a accepté votre réservation pour le trajet $from → $to',
        'data': {
          'tripId': tripId,
          'driverName': driverName,
          'from': from,
          'to': to,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur création notification confirmation: $e');
    }
  }

  // Notification de réservation refusée (pour le passager)
  static Future<void> createBookingRejectedNotification({
    required String passengerId,
    required String driverName,
    required String tripId,
    required String from,
    required String to,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': passengerId,
        'type': 'booking_rejected',
        'title': '❌ Réservation refusée',
        'message':
            '$driverName a refusé votre réservation pour le trajet $from → $to',
        'data': {
          'tripId': tripId,
          'driverName': driverName,
          'from': from,
          'to': to,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur création notification refus: $e');
    }
  }
}
