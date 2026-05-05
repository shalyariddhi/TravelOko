import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../services/places_api_service.dart';
import '../data/mock_data.dart';

class AccommodationsScreen extends StatefulWidget {
  const AccommodationsScreen({super.key});

  @override
  State<AccommodationsScreen> createState() => _AccommodationsScreenState();
}

class _AccommodationsScreenState extends State<AccommodationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedType = 'All';
  double _minPrice = 0;
  double _maxPrice = 20000;
  double _minRating = 0;
  int _minReviews = 0;

  void _showFilterSheet() {
    double tempMin = _minPrice;
    double tempMax = _maxPrice;
    double tempRating = _minRating;
    int tempReviews = _minReviews;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempMin = 0;
                            tempMax = 20000;
                            tempRating = 0;
                            tempReviews = 0;
                          });
                        },
                        child: Text('Reset', style: GoogleFonts.poppins(color: Colors.amber[800], fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Price Range ──
                  _sectionLabel('Price Range per Night', '₹${tempMin.toInt()} – ₹${tempMax.toInt()}'),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(tempMin, tempMax),
                    min: 0,
                    max: 20000,
                    divisions: 40,
                    activeColor: Colors.amber[700],
                    inactiveColor: Colors.amber.withValues(alpha: 0.2),
                    labels: RangeLabels('₹${tempMin.toInt()}', '₹${tempMax.toInt()}'),
                    onChanged: (v) => setModalState(() {
                      tempMin = v.start;
                      tempMax = v.end;
                    }),
                  ),
                  const SizedBox(height: 24),

                  // ── Star Rating ──
                  _sectionLabel('Minimum Star Rating', tempRating == 0 ? 'Any' : '${tempRating.toStringAsFixed(1)}+ ⭐'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [0.0, 3.0, 3.5, 4.0, 4.5].map((r) {
                      final selected = tempRating == r;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempRating = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? Colors.amber : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? Colors.amber[700]! : Colors.grey[300]!),
                            boxShadow: selected
                                ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 8)]
                                : [],
                          ),
                          child: Text(
                            r == 0 ? 'Any' : '${r.toStringAsFixed(1)}+',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? Colors.black : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Minimum Reviews ──
                  _sectionLabel('Minimum Reviews', tempReviews == 0 ? 'Any' : '$tempReviews+'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [0, 50, 100, 150, 200].map((r) {
                      final selected = tempReviews == r;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempReviews = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? Colors.amber : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? Colors.amber[700]! : Colors.grey[300]!),
                            boxShadow: selected
                                ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 8)]
                                : [],
                          ),
                          child: Text(
                            r == 0 ? 'Any' : '$r+',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? Colors.black : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = tempMin;
                          _maxPrice = tempMax;
                          _minRating = tempRating;
                          _minReviews = tempReviews;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Apply Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: GoogleFonts.poppins(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  final PlacesApiService _placesApiService = PlacesApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _placesApiService.fetchAccommodations('India'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading accommodations'));
          }

          final allAccommodations = snapshot.data ?? [];
          final filtered = allAccommodations.where((a) {
            final typeMatch = _selectedType == 'All' || a['type'] == _selectedType;
            final priceMatch = (a['priceNum'] as num).toInt() >= _minPrice && (a['priceNum'] as num).toInt() <= _maxPrice;
            final ratingMatch = (a['rating'] as num).toDouble() >= _minRating;
            final reviewMatch = (a['reviews'] as num).toInt() >= _minReviews;
            return typeMatch && priceMatch && ratingMatch && reviewMatch;
          }).toList();

          final hasActiveFilters = _minPrice > 0 || _maxPrice < 20000 || _minRating > 0 || _minReviews > 0;

          return CustomScrollView(
            slivers: [


          // ── Type Filters + Filter Button ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Hotel', 'Hostel', 'Rental'].map((type) {
                          final sel = _selectedType == type;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: sel ? Colors.amber : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: sel ? Colors.amber[700]! : Colors.grey[300]!),
                                boxShadow: sel
                                    ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                              ),
                              child: Text(type,
                                  style: GoogleFonts.poppins(
                                    color: sel ? Colors.black : Colors.grey[700],
                                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: hasActiveFilters ? Colors.amber : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: hasActiveFilters ? Colors.amber[700]! : Colors.grey[300]!),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded,
                              size: 18,
                              color: hasActiveFilters ? Colors.black : Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text('Filter',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: hasActiveFilters ? FontWeight.bold : FontWeight.normal,
                                color: hasActiveFilters ? Colors.black : Colors.grey[700],
                              )),
                          if (hasActiveFilters) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
          ),

          // ── Results count ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                '${filtered.length} place${filtered.length == 1 ? '' : 's'} found',
                style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ),

          // ── Cards ──
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No stays found', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Try adjusting your filters', style: GoogleFonts.poppins(color: Colors.grey[400])),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _minPrice = 0;
                            _maxPrice = 20000;
                            _minRating = 0;
                            _minReviews = 0;
                            _selectedType = 'All';
                          }),
                          icon: const Icon(Icons.refresh, color: Colors.amber),
                          label: Text('Clear all filters', style: GoogleFonts.poppins(color: Colors.amber[800], fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCard(filtered[index], index),
                      childCount: filtered.length,
                    ),
                  ),
                ),
        ],
      );
     },
    ),
   );
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final Color accentColor = item['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Image.network(
                  item['image'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 200, color: accentColor.withValues(alpha: 0.2)),
                ),
                // Badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item['badge'],
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                // Type chip
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                    ),
                    child: Text(item['type'],
                        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(item['location'],
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item['name'],
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                // Amenity chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (item['amenities'] as List<String>).map((a) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(a, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700])),
                  )).toList(),
                ),
                const SizedBox(height: 14),
                // Price + Rating + Book
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 3),
                            Text('${item['rating']}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 4),
                            Text('(${item['reviews']} reviews)',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                        const SizedBox(height: 3),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: item['price'],
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
                            ),
                            TextSpan(
                              text: ' /night',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ]),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        // Create a modified item to exclude Color because it can't be saved to Firestore
                        final dataToSave = Map<String, dynamic>.from(item)..remove('color');
                        final success = await _firebaseService.bookStay(dataToSave);
                        if (!context.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Stay Booked successfully! 🎉', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to book stay.', style: GoogleFonts.poppins()),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text('Book Now',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (index * 80).ms).slideY(begin: 0.08, end: 0);
  }
}
