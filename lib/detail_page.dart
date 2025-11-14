
import 'package:flutter/material.dart';
import 'package:myapp/models.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailPage extends StatelessWidget {
  final Person person;

  const DetailPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final bool isWalker = person is Walker;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'image_${person.imageUrl}',
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(person.imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                person.name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'About ${person.name}'),
                  const SizedBox(height: 16),
                  Text(
                    person.bio,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.6,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.withOpacity(0.2)),
                  const SizedBox(height: 24),
                  _buildStatsSection(context, isWalker),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isWalker
          ? FloatingActionButton.extended(
              onPressed: () {
                // Placeholder for booking logic
              },
              label: const Text('Book a Walk'),
              icon: const Icon(Icons.calendar_today),
              heroTag: 'book_walk',
            )
          : null,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isWalker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Statistics'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoChip(context, Icons.star_rounded, '${person.rating}', 'Rating'),
            _buildInfoChip(context, Icons.reviews_rounded, '${person.reviews}', 'Reviews'),
            _buildInfoChip(
              context,
              Icons.directions_walk_rounded,
              '${person.completedWalks}',
              'Walks',
            ),
            if (isWalker)
              _buildInfoChip(
                context,
                Icons.attach_money_rounded,
                '${(person as Walker).hourlyRate}',
                '/hr',
              ),
          ],
        ),
         if (isWalker) ...[
          const SizedBox(height: 24),
          _buildInfoRow(context, Icons.location_on, (person as Walker).location),
         ],
          if (person is Owner) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Pet Details'),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.pets, 'Name: ${(person as Owner).dogName}'),
            const SizedBox(height: 12),
            _buildInfoRow(context, Icons.cake, 'Age: ${(person as Owner).dogAge} years'),
            const SizedBox(height: 12),
            _buildInfoRow(context, Icons.category, 'Breed: ${(person as Owner).dogBreed}'),
          ]
      ],
    );
  }

    Widget _buildInfoChip(BuildContext context, IconData icon, String value, String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
