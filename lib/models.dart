
class Walker {
  final String name;
  final double rating;
  final int reviews;
  final int hourlyRate;
  final String location;
  final int completedWalks;
  final String imageUrl;
  final String bio;

  const Walker({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.hourlyRate,
    required this.location,
    required this.completedWalks,
    required this.imageUrl,
    required this.bio,
  });
}

class Owner {
  final String name;
  final int dogAge;
  final String dogBreed;
  final double rating;
  final int reviews;
  final int completedWalks;
  final String imageUrl;
  final String bio;

  const Owner({
    required this.name,
    required this.dogAge,
    required this.dogBreed,
    required this.rating,
    required this.reviews,
    required this.completedWalks,
    required this.imageUrl,
    required this.bio,
  });
}
