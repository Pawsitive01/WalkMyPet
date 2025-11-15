import 'package:flutter/material.dart';
import 'package:walkmypet/models.dart';

class DetailPage extends StatelessWidget {
  final Person person;

  const DetailPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'image_${person.imageUrl}',
              child: CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage(person.imageUrl),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              person.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              person.bio,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
