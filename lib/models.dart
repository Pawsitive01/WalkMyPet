class Person {
  final String name;
  final double rating;
  final int reviews;
  final int completedWalks;
  final String imageUrl;
  final String bio;
  final bool hasPoliceClearance;

  const Person({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.completedWalks,
    required this.imageUrl,
    required this.bio,
    required this.hasPoliceClearance,
  });
}

class Walker extends Person {
  final int hourlyRate; // Base hourly rate (for Walking service)
  final String location;
  final List<String> services; // e.g., ['Walking', 'Grooming', 'Sitting']
  final Map<String, int> servicePrices; // Prices for each service

  const Walker({
    required super.name,
    required super.rating,
    required super.reviews,
    required super.completedWalks,
    required super.imageUrl,
    required super.bio,
    required super.hasPoliceClearance,
    required this.hourlyRate,
    required this.location,
    this.services = const ['Walking'],
    this.servicePrices = const {},
  });

  // Get price for a specific service, fallback to hourlyRate
  int getServicePrice(String service) {
    return servicePrices[service] ?? hourlyRate;
  }
}

class Owner extends Person {
  final String dogName;
  final int dogAge;
  final String dogBreed;
  final int likes;

  const Owner({
    required super.name,
    required super.rating,
    required super.reviews,
    required super.completedWalks,
    required super.imageUrl,
    required super.bio,
    required super.hasPoliceClearance,
    required this.dogName,
    required this.dogAge,
    required this.dogBreed,
    required this.likes,
  });
}
