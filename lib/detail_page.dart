
import 'package:flutter/material.dart';
import 'package:myapp/models.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailPage extends StatelessWidget {
  final dynamic person;

  const DetailPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final bool isWalker = person is Walker;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                person.name,
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Hero(
                tag: person.imageUrl,
                child: Image.asset(
                  person.imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withAlpha(102),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Bio'),
                  const SizedBox(height: 8),
                  Text(
                    person.bio,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(context, Icons.star, '${person.rating} (${person.reviews} reviews)'),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.directions_walk, '${person.completedWalks} completed walks'),
                  if (isWalker) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Icons.attach_money, '\$${(person as Walker).hourlyRate}/hr'),
                     const SizedBox(height: 16),
                    _buildInfoRow(context, Icons.location_on, (person as Walker).location),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isWalker
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    // Placeholder for booking logic
                  },
                  label: const Text('Book a Walk'),
                  icon: const Icon(Icons.calendar_today),
                  heroTag: 'book_walk',
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  onPressed: () {
                    // Placeholder for messaging logic
                  },
                  label: Text('Message ${person.name}'),
                  icon: const Icon(Icons.message),
                  heroTag: 'message_user',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.oswald(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
          ),
        ),
      ],
    );
  }
}
