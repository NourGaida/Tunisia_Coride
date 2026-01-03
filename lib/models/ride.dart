import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final Driver driver;
  final String from;
  final String to;
  final DateTime date;
  final String time;
  final double price;
  final int seats; // Nombre total de sièges
  final int availableSeats; // Places disponibles
  final String description;
  final String status;

  Ride({
    required this.id,
    required this.driver,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.price,
    required this.seats,
    required this.availableSeats,
    required this.description,
    required this.status,
  });

  factory Ride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime tripDateTime = (data['date'] as Timestamp).toDate();

    return Ride(
      id: doc.id,
      driver: Driver.fromFirestore(data),
      from: data['departureLocation'] as String? ?? 'N/A',
      to: data['arrivalLocation'] as String? ?? 'N/A',
      date: tripDateTime,
      time:
          '${tripDateTime.hour.toString().padLeft(2, '0')}:${tripDateTime.minute.toString().padLeft(2, '0')}',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      seats: (data['seats'] as num?)?.toInt() ??
          (data['availableSeats'] as num?)?.toInt() ??
          0,
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
    );
  }
}

class Driver {
  final String id;
  final String name;
  final String? avatar;
  final double rating;
  final int trips;
  final String bio;

  Driver({
    required this.id,
    required this.name,
    this.avatar,
    required this.rating,
    required this.trips,
    required this.bio,
  });

  factory Driver.fromFirestore(Map<String, dynamic> rideData) {
    return Driver(
      id: rideData['driverId'] as String? ?? '',
      name: rideData['driverName'] as String? ?? 'Conducteur Inconnu',
      avatar: rideData['driverAvatarUrl'] as String?,
      rating: (rideData['driverRating'] as num?)?.toDouble() ?? 0.0,
      trips: (rideData['driverTrips'] as num?)?.toInt() ?? 0,
      bio: rideData['driverBio'] as String? ?? '',
    );
  }
}
