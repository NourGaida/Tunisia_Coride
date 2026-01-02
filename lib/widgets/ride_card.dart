import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart'; // Importez pour le formatage de date

class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onTap;

  const RideCard({
    super.key,
    required this.ride,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              // Driver info
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary
                        .withValues(alpha: 0.1), // Rétabli withValues
                    backgroundImage: ride.driver.avatar != null &&
                            ride.driver.avatar!.isNotEmpty
                        ? NetworkImage(ride.driver.avatar!) as ImageProvider
                        : null,
                    child: (ride.driver.avatar == null ||
                            ride.driver.avatar!.isEmpty)
                        ? Text(
                            ride.driver.name.isNotEmpty
                                ? ride.driver.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Name and trips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.driver.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          '${ride.driver.trips} trajets', // Utilise le champ 'trips' du Driver
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ride.driver.rating
                              .toStringAsFixed(1), // Affiche 1 décimale
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Route
              Row(
                children: [
                  // Departure
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.from,
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
                  // Arrival
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.to,
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

              // Date, time, seats
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    text: DateFormat('dd MMM')
                        .format(ride.date), // Utilise le DateTime
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.access_time,
                    text: ride.time,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.person_outline,
                    text:
                        '${ride.availableSeats} places disponibles', // Affiche les places DISPONIBLES
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Price and availability
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${ride.price.toInt()} TND',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(
                          text: ' / personne',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Availability badge (conditionnel basé sur availableSeats)
                  if (ride.availableSeats > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent
                            .withValues(alpha: 0.1), // Rétabli withValues
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ride.availableSeats} disponible${ride.availableSeats > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error
                            .withValues(alpha: 0.1), // Rétabli withValues
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Complet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
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
    return Expanded(
      // Expanded pour une meilleure mise en page si le texte est long
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Flexible(
            // pour que le texte ne déborde pas
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              overflow:
                  TextOverflow.ellipsis, // Coupe le texte s'il est trop long
            ),
          ),
        ],
      ),
    );
  }
}
