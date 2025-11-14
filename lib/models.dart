
abstract class Person {
  final String name;
  final String imageUrl;
  final double rating;
  final int reviews;
  final int completedWalks;
  final String bio;

  const Person({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.completedWalks,
    required this.bio,
  });
}

class Walker extends Person {
  final int hourlyRate;
  final String location;

  const Walker({
    required super.name,
    required super.imageUrl,
    required super.rating,
    required super.reviews,
    required super.completedWalks,
    required super.bio,
    required this.hourlyRate,
    required this.location,
  });
}

class Owner extends Person {
  final String dogName;
  final int dogAge;
  final String dogBreed;

  const Owner({
    required super.name,
    required super.imageUrl,
    required super.rating,
    required super.reviews,
    required super.completedWalks,
    required super.bio,
    required this.dogName,
    required this.dogAge,
    required this.dogBreed,
  });
}
