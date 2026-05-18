import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/places_api_service.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AccommodationsScreen extends StatefulWidget {
  final bool isEmbedded;
  final String initialQuery;
  const AccommodationsScreen({
    super.key,
    this.isEmbedded = false,
    this.initialQuery = '',
  });

  @override
  State<AccommodationsScreen> createState() => _AccommodationsScreenState();
}

class _AccommodationsScreenState extends State<AccommodationsScreen> {

  final PlacesApiService _placesApiService = PlacesApiService();
  String _selectedType = 'All';
  double _minPrice = 0;
  double _maxPrice = 20000;
  double _minRating = 0;
  int _minReviews = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery;
    _searchController.text = widget.initialQuery;
  }

  @override
  void didUpdateWidget(AccommodationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When ExploreScreen's search query changes, sync it here
    if (widget.initialQuery != oldWidget.initialQuery) {
      setState(() {
        _searchQuery = widget.initialQuery;
        _searchController.text = widget.initialQuery;
      });
    }
  }

  void _showFilterSheet() {
    double tempMin = _minPrice;
    double tempMax = _maxPrice;
    double tempRating = _minRating;
    int tempReviews = _minReviews;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters',
                          style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempMin = 0;
                              tempMax = 20000;
                              tempRating = 0;
                              tempReviews = 0;
                            });
                          },
                          child: Text('Reset',
                              style: GoogleFonts.poppins(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold)))
                    ],
                  ),
                  const SizedBox(height: 24),
                  // ── Price Range ──
                  _sectionLabel('Price Range per Night',
                      '₹${tempMin.toInt()} – ₹${tempMax.toInt()}'),
                  const SizedBox(height: 8),
                  RangeSlider(
                      values: RangeValues(tempMin, tempMax),
                      min: 0,
                      max: 20000,
                      divisions: 40,
                      activeColor: Colors.amber[700],
                      inactiveColor: Colors.amber.withValues(alpha: 0.2),
                      labels: RangeLabels('₹${tempMin.toInt()}',
                          '₹${tempMax.toInt()}'),
                      onChanged: (v) => setModalState(() {
                            tempMin = v.start;
                            tempMax = v.end;
                          })),
                  const SizedBox(height: 24),
                  // ── Star Rating ──
                  _sectionLabel(
                      'Minimum Star Rating',
                      tempRating == 0
                          ? 'Any'
                          : '${tempRating.toStringAsFixed(1)}+ ⭐'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [0.0, 3.0, 3.5, 4.0, 4.5]
                        .map((r) {
                          final selected = tempRating == r;
                          return GestureDetector(
                            onTap: () => setModalState(() => tempRating = r),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.amber
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: selected
                                        ? Colors.amber[700]!
                                        : Colors.grey[300]!),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                            color: Colors.amber
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8)
                                      ]
                                    : [],
                              ),
                              child: Text(
                                r == 0 ? 'Any' : '${r.toStringAsFixed(1)}+',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selected
                                        ? Colors.black
                                        : Colors.grey[700]),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  // ── Minimum Reviews ──
                  _sectionLabel('Minimum Reviews',
                      tempReviews == 0 ? 'Any' : '$tempReviews+'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [0, 50, 100, 150, 200]
                        .map((r) {
                          final selected = tempReviews == r;
                          return GestureDetector(
                            onTap: () => setModalState(() => tempReviews = r),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.amber
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: selected
                                        ? Colors.amber[700]!
                                        : Colors.grey[300]!),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                            color: Colors.amber
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8)
                                      ]
                                    : [],
                              ),
                              child: Text(
                                r == 0 ? 'Any' : '$r+',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selected
                                        ? Colors.black
                                        : Colors.grey[700]),
                              ),
                            ),
                          );
                        })
                        .toList(),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0),
                        child: Text('Apply Filters',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16))),
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
        Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 15)),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(value,
                style: GoogleFonts.poppins(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12)))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final borderColor = Theme.of(context).dividerColor;

    return Scaffold(
        backgroundColor: bg,
        // Hide AppBar when embedded inside ExploreScreen (it already has a search bar)
        appBar: widget.isEmbedded ? null : AppBar(
          backgroundColor: bg,
          elevation: 0,
          title: Text('Stays',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: textPrimary)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search city or destination...',
                    hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.black38),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.tune_rounded,
                          color: (_minPrice > 0 || _maxPrice < 20000 || _minRating > 0 || _minReviews > 0)
                              ? const Color(0xFFFF8C00)
                              : Colors.black38),
                      onPressed: _showFilterSheet,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (value) {
                    _searchQuery = value.trim();
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
        body: Column(children: [
          Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _placesApiService.fetchAccommodations(
                      _searchQuery.isEmpty ? 'India' : _searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Error loading accommodations'));
                    }
                    final allAccommodations = snapshot.data ?? [];
                    final filtered = allAccommodations.where((a) {
                      final typeMatch =
                          _selectedType == 'All' || a['type'] == _selectedType;
                      final priceMatch = (a['priceNum'] as num)
                              .toInt() >=
                          _minPrice &&
                          (a['priceNum'] as num).toInt() <= _maxPrice;
                      final ratingMatch =
                          (a['rating'] as num).toDouble() >= _minRating;
                      final reviewMatch =
                          (a['reviews'] as num).toInt() >= _minReviews;
                      return typeMatch &&
                          priceMatch &&
                          ratingMatch &&
                          reviewMatch;
                    }).toList();
                    return CustomScrollView(slivers: [
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 12, 16, 8),
                              child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      children: ['All',
                                              'Hotel',
                                              'Hostel',
                                              'Dormitory']
                                          .map((type) {
                                        final sel = _selectedType == type;
                                        return GestureDetector(
                                          onTap: () => setState(() => _selectedType = type),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: const EdgeInsets.only(right: 10),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                            decoration: BoxDecoration(
                                                color: sel
                                                    ? const Color(0xFFFF8C00)
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(22),
                                                border: Border.all(
                                                    color: sel
                                                        ? const Color(0xFFFF8C00)
                                                        : const Color(0xFFE0E0E0)),
                                                boxShadow: sel
                                                    ? [
                                                        BoxShadow(
                                                            color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                                                            blurRadius: 12,
                                                            offset: const Offset(0, 3))
                                                      ]
                                                    : [
                                                        BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.05),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2))
                                                      ]),
                                            child: Text(type,
                                                style: GoogleFonts.poppins(
                                                    color: sel ? Colors.white : Colors.black54,
                                                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                                    fontSize: 13)),
                                          ),
                                        );
                                      }).toList())))),
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                              child: Text(
                                  '${filtered.length} place${filtered.length == 1 ? '' : 's'} found',
                                  style: GoogleFonts.poppins(
                                      color: Colors.black45,
                                      fontSize: 12)))),
                      filtered.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off_rounded,
                                            size: 64,
                                            color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text('No stays found',
                                            style: GoogleFonts.poppins(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Colors.grey[600],
                                                fontSize: 18)),
                                        const SizedBox(height: 8),
                                        Text('Try adjusting your filters',
                                            style: GoogleFonts.poppins(
                                                color: Colors.grey[400])),
                                        const SizedBox(height: 20),
                                        TextButton.icon(
                                            onPressed: () => setState(() {
                                                  _minPrice = 0;
                                                  _maxPrice = 20000;
                                                  _minRating = 0;
                                                  _minReviews = 0;
                                                  _selectedType = 'All';
                                                }),
                                            icon: const Icon(Icons.refresh,
                                                color: Colors.amber),
                                            label: Text('Clear all filters',
                                                style: GoogleFonts.poppins(
                                                    color:
                                                        Colors.amber[800],
                                                    fontWeight:
                                                        FontWeight.bold)))
                                      ])))
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 100),
                              sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildCard(
                                          filtered[index], index),
                                      childCount: filtered.length)))
                    ]);
                  }))
        ]));
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final Color accentColor = item['color'] as Color;
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(children: [
                    Image.network(item['image'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: accentColor.withValues(alpha: 0.2))),
                    Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 10)
                                ]),
                            child: Text(item['badge'],
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)))),
                    Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                            child: Text(item['type'],
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600))))
                  ])),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.location_on_rounded,
                              color: Color(0xFFFF8C00), size: 12),
                          const SizedBox(width: 4),
                          Text(item['location'],
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black45))
                        ]),
                        const SizedBox(height: 4),
                        Text(item['name'],
                            style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (item['amenities'] as List<String>)
                                .map((a) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF4F6FA),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE0E0E0))),
                                    child: Text(a,
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.black54))))
                                .toList()),
                        const SizedBox(height: 14),
                        Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.star_rounded,
                                          color: Colors.amber, size: 16),
                                      const SizedBox(width: 3),
                                      Text('${item['rating']}',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.black87)),
                                      const SizedBox(width: 4),
                                      Text('(${item['reviews']} reviews)',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.black45))
                                    ]),
                                    const SizedBox(height: 3),
                                    RichText(
                                        text: TextSpan(children: [
                                      TextSpan(
                                          text: item['price'],
                                          style: GoogleFonts.outfit(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black87)),
                                      TextSpan(
                                          text: ' /night',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.black38))
                                    ]))
                                  ]),
                              GestureDetector(
                                  onTap: () async {
                                    final hotelName = item['name'] as String? ?? 'hotel';
                                    final vendor = RemoteConfigService().affiliateVendorName;
                                    final affiliateUrl = Uri.parse(
                                        'https://www.booking.com/searchresults.html?ss=${Uri.encodeComponent(hotelName)}');
                                    // 🔴 Track click BEFORE navigating away
                                    await AnalyticsService().trackAffiliateClick(
                                      hotelName: hotelName,
                                      vendor: vendor,
                                      affiliateUrl: affiliateUrl.toString(),
                                    );
                                    if (await canLaunchUrl(affiliateUrl)) {
                                      await launchUrl(affiliateUrl, mode: LaunchMode.externalApplication);
                                    } else {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Could not launch booking partner.'),
                                        backgroundColor: Colors.redAccent,
                                      ));
                                    }
                                  },
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 22, vertical: 12),
                                      decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.amber
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4))
                                          ]),
                                      child: Text('Book via Booking.com',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 13))))
                            ]),
                      ]),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: (index * 80).ms).slideY(begin: 0.08, end: 0);
  }
}
