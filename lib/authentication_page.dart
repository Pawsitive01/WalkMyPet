import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Registration Page'),
    );
  }
}

class AuthenticationPage extends StatelessWidget {
  final String personName;
  final bool isWalker;
  final double rating;
  final String personImage;

  const AuthenticationPage({
    super.key,
    required this.personName,
    required this.isWalker,
    required this.rating,
    required this.personImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${isWalker ? 'Walker' : 'Owner'}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(personImage),
            ),
            const SizedBox(height: 20),
            Text(
              personName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 5),
                Text(
                  rating.toString(),
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to a booking confirmation page
              },
              child: Text('Book ${isWalker ? 'Walker' : 'Owner'}'),
            ),
          ],
        ),
      ),
    );
  }
}