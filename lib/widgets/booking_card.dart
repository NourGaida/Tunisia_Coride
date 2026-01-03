import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

/// Widget pour afficher une réservation avec le même style que RideCard
class BookingCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.bookingData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tripDetails =
        bookingData['tripDetails'] as Map<String, dynamic>? ?? {};
    final status = bookingData['status'] as String? ?? 'unknown';

    final from = tripDetails['from'] as String? ?? 'N/A';
    final to = tripDetails['to'] as String? ?? 'N/A';

    // Lire le prix depuis 'totalPrice' au niveau racine du bookingData
    final price = (bookingData['totalPrice'] as num?)?.toDouble() ?? 0.0;

    // Récupération de la date
    DateTime? tripDate;
    String dateStr = "Date inconnue";
    String timeStr = "--:--";

    if (tripDetails['date'] != null && tripDetails['date'] is Timestamp) {
      tripDate = (tripDetails['date'] as Timestamp).toDate();
      // Utilisation de la locale française pour les mois
      dateStr = DateFormat('dd MMM', 'fr')
          .format(tripDate); // 'fr' pour la locale française
      timeStr = DateFormat('HH:mm').format(tripDate);
    }

    // Lire le nom du conducteur depuis 'driverName' stocké dans le bookingData
    final driverName =
        bookingData['driverName'] as String? ?? 'Conducteur Inconnu';
    final driverAvatar =
        bookingData['driverAvatar'] as String?; // Si vous stockez l'avatar ici

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Conducteur + Statut
              Row(
                children: [
                  // Avatar conducteur
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary
                        .withValues(alpha: 0.1), // Rétabli withValues
                    backgroundImage:
                        driverAvatar != null && driverAvatar.isNotEmpty
                            ? NetworkImage(driverAvatar) as ImageProvider
                            : null,
                    child: (driverAvatar == null || driverAvatar.isEmpty)
                        ? Text(
                            driverName.isNotEmpty
                                ? driverName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Nom conducteur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName, // <<< Affiche le nom du conducteur
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Text(
                          'Conducteur', // Toujours 'Conducteur' ici
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge de statut
                  _buildStatusBadge(status),
                ],
              ),

              const SizedBox(height: 16),

              // Itinéraire
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      from,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      to,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date, heure, prix
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    text: dateStr,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.access_time,
                    text: timeStr,
                  ),
                  const Spacer(),

                  // Prix
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${price.toInt()} TND', // <<< Affiche le prix correct
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'confirmed':
        color = AppColors.success;
        text = 'Confirmé';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = AppColors.warning; // Couleur pour 'pending'
        text = 'En attente';
        icon = Icons.access_time_filled;
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'Refusé';
        icon = Icons.cancel;
        break;
      case 'completed':
        color = Colors.grey;
        text = 'Terminé';
        icon = Icons.flag;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // Rétabli withValues
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color.withValues(alpha: 0.2)), // Rétabli withValues
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
