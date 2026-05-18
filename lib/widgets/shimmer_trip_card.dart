import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer placeholder that mimics the shape of a [TripCard].
/// Drop this in wherever you'd normally show a loading indicator.
class ShimmerTripCard extends StatelessWidget {
  const ShimmerTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organizer row
                  Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: baseColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 120, height: 12, color: baseColor),
                      const Spacer(),
                      Container(width: 70, height: 12, color: baseColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Budget bar
                  Container(width: double.infinity, height: 12, color: baseColor),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(width: 24, height: 6, color: baseColor),
                    const SizedBox(width: 4),
                    Container(width: 24, height: 6, color: baseColor),
                    const SizedBox(width: 4),
                    Container(width: 24, height: 6, color: baseColor),
                    const SizedBox(width: 4),
                    Container(width: 24, height: 6, color: baseColor),
                  ]),
                  const SizedBox(height: 16),
                  // Tags row
                  Row(children: [
                    Container(width: 60, height: 24, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 8),
                    Container(width: 80, height: 24, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 8),
                    Container(width: 50, height: 24, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(12))),
                  ]),
                  const SizedBox(height: 16),
                  // Button placeholder
                  Container(
                    width: double.infinity, height: 48,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(16),
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

/// A shimmer list — use this as the loading child in StreamBuilder / FutureBuilder
class ShimmerTripList extends StatelessWidget {
  final int count;
  const ShimmerTripList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: count,
      itemBuilder: (_, __) => const ShimmerTripCard(),
    );
  }
}

/// A compact shimmer row — for small list items like bookings
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 14, color: baseColor),
                const SizedBox(height: 8),
                Container(width: 120, height: 12, color: baseColor),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
