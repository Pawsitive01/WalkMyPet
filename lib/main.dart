import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models.dart';
import 'package:myapp/detail_page.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Color(0xFF5865F2); // Blurple

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
        fontSize: 57,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
      labelLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: primarySeedColor,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withAlpha(178),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.grey[900],
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withAlpha(178),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFB3B9F7),
        foregroundColor: Colors.black,
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Walk My Pet',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets),
              SizedBox(width: 8),
              Text('Walk My Pet'),
              SizedBox(width: 8),
              Icon(Icons.pets),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
              tooltip: 'Toggle Theme',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                child: Text(
                  'Pet Walkers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  'Pet Owners',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WalkerList(),
            OwnerList(),
          ],
        ),
      ),
    );
  }
}

class WalkerList extends StatelessWidget {
  const WalkerList({super.key});

  @override
  Widget build(BuildContext context) {
    final walkers = [
       const Walker(
        name: 'John Doe',
        rating: 4.5,
        reviews: 120,
        hourlyRate: 25,
        location: 'Adelaide, Australia',
        completedWalks: 150,
        imageUrl: 'https://i.pravatar.cc/150?img=68',
        bio: 'I am a dog lover and I have been walking dogs for 5 years. I am very responsible and I will take good care of your dog.',
      ),
      const Walker(
        name: 'Jane Smith',
        rating: 5.0,
        reviews: 200,
        hourlyRate: 30,
        location: 'Los Angeles, CA',
        completedWalks: 250,
        imageUrl: 'https://i.pravatar.cc/150?img=47',
        bio: 'I am a certified dog walker and I have been working with dogs for over 10 years. I am also a certified dog trainer.',
      ),
      const Walker(
        name: 'Sam Wilson',
        rating: 4.2,
        reviews: 90,
        hourlyRate: 22,
        location: 'Adelaide, Australia',
        completedWalks: 120,
        imageUrl: 'https://i.pravatar.cc/150?img=11',
        bio: 'I am a student and I love dogs. I am available for walks in the afternoon and on weekends.',
      ),
    ];

    return ListView.builder(
      itemCount: walkers.length,
      itemBuilder: (context, index) {
        return WalkerCard(walker: walkers[index]);
      },
    );
  }
}

class OwnerList extends StatelessWidget {
  const OwnerList({super.key});

  @override
  Widget build(BuildContext context) {
    final owners = [
      const Owner(
        name: 'Richard Roe',
        dogAge: 3,
        dogBreed: 'Golden Retriever',
        rating: 4.8,
        reviews: 80,
        completedWalks: 100,
        imageUrl: 'https://i.pravatar.cc/150?img=32',
        bio: 'My dog, Max, is a very friendly and energetic Golden Retriever. He loves to play fetch and go for long walks.',
      ),
       const Owner(
        name: 'Mary Major',
        dogAge: 2,
        dogBreed: 'French Bulldog',
        rating: 4.9,
        reviews: 95,
        completedWalks: 120,
        imageUrl: 'https://i.pravatar.cc/150?img=31',
        bio: 'Bella is a sweet and playful French Bulldog. She is very good with other dogs and loves to cuddle.',
      ),
      const Owner(
        name: 'Peter Jones',
        dogAge: 5,
        dogBreed: 'Labrador',
        rating: 4.2,
        reviews: 60,
        completedWalks: 80,
        imageUrl: 'https://i.pravatar.cc/150?img=12',
        bio: 'Buddy is a calm and gentle Labrador. He is very well-behaved and loves to go for walks in the park.',
      ),
    ];

    return ListView.builder(
      itemCount: owners.length,
      itemBuilder: (context, index) {
        return OwnerCard(owner: owners[index]);
      },
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  const StarRating({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }
}

class WalkerCard extends StatelessWidget {
  final Walker walker;

  const WalkerCard({super.key, required this.walker});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(person: walker),
          ),
        );
      },
      child: Card(
        color: const Color(0xffabb2f8),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 8,
        shadowColor: const Color.fromRGBO(0, 0, 0, 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Hero(
                tag: walker.imageUrl,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(walker.imageUrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walker.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.green, size: 20),
                        SizedBox(width: 4),
                        Text('Police Clearance', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${walker.hourlyRate}/hr',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(walker.location, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '${walker.completedWalks} completed walks',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StarRating(rating: walker.rating),
                        const SizedBox(width: 4),
                        Text(
                          '(${walker.reviews} reviews)',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OwnerCard extends StatelessWidget {
  final Owner owner;

  const OwnerCard({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(person: owner),
          ),
        );
      },
      child: Card(
        color: const Color(0xffdde0fc),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 8,
        shadowColor: const Color.fromRGBO(0, 0, 0, 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Hero(
                tag: owner.imageUrl,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(owner.imageUrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${owner.dogAge}-year-old ${owner.dogBreed}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${owner.completedWalks} completed walks',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StarRating(rating: owner.rating),
                        const SizedBox(width: 4),
                        Text(
                          '(${owner.reviews} reviews)',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
