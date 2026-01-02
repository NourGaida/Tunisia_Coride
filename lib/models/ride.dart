import 'package:cloud_firestore/cloud_firestore.dart'; // Importez pour Timestamp

class Ride {
  final String id;
  final Driver driver;
  final String from;
  final String to;
  final DateTime date;
  final String time; // Représentation de l'heure comme "HH:MM"
  final double price;
  final int seats; // Nombre total de sièges offerts
  final int availableSeats; // Nombre de sièges encore disponibles
  final String description;
  final String
      status; // Statut du trajet (e.g., 'upcoming', 'completed', 'cancelled')

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

  // Constructeur factory pour créer un objet Ride à partir d'un DocumentSnapshot Firestore
  factory Ride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convertir le Timestamp Firestore en DateTime
    final DateTime tripDateTime = (data['date'] as Timestamp).toDate();

    return Ride(
      id: doc.id,
      driver: Driver.fromFirestore(
          data), // Crée le Driver à partir des données du trajet
      from: data['departureLocation'] as String? ?? 'N/A',
      to: data['arrivalLocation'] as String? ?? 'N/A',
      date: tripDateTime,
      // Pour l'heure, nous la formatons à partir du DateTime.
      // Si 'time' est stocké comme une string séparée dans Firestore, utilisez : data['time'] as String? ?? '',
      time:
          '${tripDateTime.hour.toString().padLeft(2, '0')}:${tripDateTime.minute.toString().padLeft(2, '0')}',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      seats: (data['totalSeats'] as num?)?.toInt() ??
          0, // Assurez-vous d'avoir 'totalSeats' en BDD
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
    );
  }
}

class Driver {
  final String id; // L'UID Firebase du conducteur
  final String name;
  final String? avatar; // URL de l'avatar (peut être null)
  final double rating;
  final int trips; // Nombre de trajets effectués par le conducteur
  final String bio;

  Driver({
    required this.id,
    required this.name,
    this.avatar,
    required this.rating,
    required this.trips,
    required this.bio,
  });

  // Constructeur factory pour créer un objet Driver à partir des données d'un trajet (rideData)
  // Note: Pour une application complète, rating, trips, bio et avatar devraient
  // idéalement être récupérés depuis un document 'users' séparé via 'driverId'.
  // Ici, nous prenons des valeurs par défaut ou des valeurs si elles sont passées dans rideData.
  factory Driver.fromFirestore(Map<String, dynamic> rideData) {
    return Driver(
      id: rideData['driverId'] as String? ?? '',
      name: rideData['driverName'] as String? ?? 'Conducteur Inconnu',
      // Ces champs sont souvent stockés dans le document utilisateur du driver,
      // pas directement dans le document du trajet pour éviter la duplication.
      // Pour le moment, on utilise des valeurs statiques/par défaut.
      avatar: rideData['driverAvatarUrl']
          as String?, // Si vous le stockez dans le trajet
      rating: (rideData['driverRating'] as num?)?.toDouble() ?? 0.0,
      trips: (rideData['driverTrips'] as num?)?.toInt() ?? 0,
      bio: rideData['driverBio'] as String? ?? '',
    );
  }
}
