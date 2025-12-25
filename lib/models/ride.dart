class Ride {
  final String id;
  final Driver driver;
  final String from;
  final String to;
  final String date;
  final String time;
  final double price;
  final int seats;
  final String description;

  Ride({
    required this.id,
    required this.driver,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.price,
    required this.seats,
    required this.description,
  });
}

class Driver {
  final String name;
  final String avatar;
  final double rating;
  final int trips;
  final String bio;

  Driver({
    required this.name,
    required this.avatar,
    required this.rating,
    required this.trips,
    required this.bio,
  });
}
