import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/trip.dart';

class TripCard extends StatefulWidget {
  final Trip trip;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;
  final bool isJoined;
  final bool showWishlist;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  const TripCard({
    super.key,
    required this.trip,
    this.onJoin,
    this.onTap,
    this.isJoined = false,
    this.showWishlist = false,
    this.isWishlisted = false,
    this.onWishlistToggle,
  });

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  bool _hasJoined = false;

  String _budgetLabel(int budget) {
    if (budget <= 10000) return 'Economy';
    if (budget <= 25000) return 'Standard';
    if (budget <= 50000) return 'Premium';
    return 'Luxury';
  }

  Color _budgetColor(int budget) {
    if (budget <= 10000) return const Color(0xFF10B981); // Emerald
    if (budget <= 25000) return const Color(0xFF34D399); // Mint
    if (budget <= 50000) return const Color(0xFF6C5DD3); // Purple/Secondary
    return const Color(0xFFFF5E3A); // Sunset Coral/Primary
  }

  int _budgetLevel(int budget) {
    if (budget <= 10000) return 1;
    if (budget <= 25000) return 2;
    if (budget <= 50000) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final dateStr = DateFormat('d MMM yyyy').format(trip.startDate);
    final seatsPercent = (trip.totalSeats - trip.seatsLeft) / trip.totalSeats;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFF1F6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + Badges ──────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(23)),
                  child: CachedNetworkImage(
                    imageUrl: trip.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 220,
                      color: const Color(0xFFEFF1F6),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 220,
                      color: const Color(0xFFEFF1F6),
                      child: Icon(Icons.image, size: 60, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(23)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Girliees badge
                if (trip.isOnlyGirls)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.pink[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.female,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('Girliees',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                // Wishlist Button
                if (widget.showWishlist)
                  Positioned(
                    top: 14,
                    right: trip.durationDays > 0 ? 80 : 14,
                    child: GestureDetector(
                      onTap: widget.onWishlistToggle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                          ],
                        ),
                        child: Icon(
                          widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: widget.isWishlisted ? Colors.red : const Color(0xFF8A99AD),
                          size: 18,
                        ).animate(target: widget.isWishlisted ? 1 : 0).scaleXY(end: 1.2, duration: 200.ms).then().scaleXY(end: 1 / 1.2),
                      ),
                    ),
                  ),
                // Duration badge
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text('${trip.durationDays}D',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                // Bottom-left: title + location
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.title,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(trip.destination,
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Body ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organizer row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFEFF1F6),
                        backgroundImage:
                            CachedNetworkImageProvider(trip.organizerAvatar),
                        child: Icon(Icons.person, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(trip.organizerName,
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ),
                      Icon(Icons.calendar_today,
                          size: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Budget meter + seats
                  Row(
                    children: [
                      // Budget meter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '₹${NumberFormat('#,##,###').format(trip.budget)}  •  ${_budgetLabel(trip.budget)}',
                                style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color)),
                            const SizedBox(height: 5),
                            Row(
                              children: List.generate(4, (i) {
                                final filled = i < _budgetLevel(trip.budget);
                                return Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  width: 20,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: filled
                                        ? _budgetColor(trip.budget)
                                        : const Color(0xFFEFF1F6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Seats progress
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${trip.seatsLeft} seats left',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: trip.seatsLeft <= 2
                                      ? Colors.redAccent
                                      : Theme.of(context).primaryColor)),
                          const SizedBox(height: 5),
                          SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              value: seatsPercent,
                              backgroundColor: const Color(0xFFEFF1F6),
                              color: trip.seatsLeft <= 2
                                  ? Colors.redAccent
                                  : Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: trip.tags.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final tag = entry.value;
                      final isEven = idx % 2 == 0;
                      final color = isEven ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(tag,
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  if (_hasJoined || widget.isJoined) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hotel, color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Confirmed Stay: Partner Hotel',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 14),
                  ],

                  // Join Button (pulsing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_hasJoined || widget.isJoined)
                          ? null
                          : () {
                              setState(() => _hasJoined = true);
                              widget.onJoin?.call();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_hasJoined || widget.isJoined) ? const Color(0xFFEFF1F6) : Theme.of(context).primaryColor,
                        foregroundColor:
                            (_hasJoined || widget.isJoined) ? const Color(0xFF8A99AD) : Colors.white,
                        shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                        elevation: (_hasJoined || widget.isJoined) ? 0 : 8,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        (_hasJoined || widget.isJoined) ? 'Joined ✓' : 'Join Trip',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ).animate(
                      onPlay: (controller) =>
                          (_hasJoined || widget.isJoined) ? null : controller.repeat(reverse: true),
                    ).scaleXY(
                      begin: 1.0,
                      end: 1.03,
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

