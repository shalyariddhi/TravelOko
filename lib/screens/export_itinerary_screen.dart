import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportItineraryScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final List<Map<String, dynamic>> itineraryDays;

  const ExportItineraryScreen({
    super.key,
    required this.requestData,
    required this.itineraryDays,
  });

  @override
  State<ExportItineraryScreen> createState() => _ExportItineraryScreenState();
}

class _ExportItineraryScreenState extends State<ExportItineraryScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  Future<void> _shareItinerary() async {
    setState(() => _isExporting = true);
    
    try {
      final directory = await getTemporaryDirectory();

      
      final imageFile = await _screenshotController.captureAndSave(
        directory.path,
        fileName: 'itinerary_export_${DateTime.now().millisecondsSinceEpoch}.png',
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 100),
      );

      if (imageFile != null) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imageFile)],
          text: 'Check out my upcoming trip to ${widget.requestData['destination']} planned with Travel-Loco! ✈️🌍',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e', style: GoogleFonts.poppins())),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.requestData['destination'] ?? 'Unknown Destination';
    final days = widget.requestData['days'] ?? 3;
    final style = widget.requestData['style'] ?? 'Relaxing';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Export Itinerary', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1C),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 5),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF8C42), Color(0xFFFFB347)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.flight_takeoff, color: Colors.white, size: 28),
                                      const SizedBox(width: 8),
                                      Text('GO-Trivo', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                                    child: Text('$days Days', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(destination.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2)),
                              const SizedBox(height: 8),
                              Text('$style Trip • Planned by AI', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
                            ],
                          ),
                        ),
                        // Days Preview (Max 3 for snapshot)
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.itineraryDays.take(3).map((dayData) {
                              final dayNum = dayData['day'] ?? 1;
                              final places = List<Map<String, dynamic>>.from(dayData['places'] ?? []);
                              final topPlace = places.isNotEmpty ? places.first['name'] : 'Exploring the city';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Text('DAY $dayNum', style: GoogleFonts.outfit(color: Colors.amber[800], fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(topPlace, style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text('${places.length} activities planned', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // Footer
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          color: const Color(0xFFF5F5F5),
                          child: Column(
                            children: [
                              Text('Ready to pack your bags? 🎒', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('Download Go-Trivo to plan yours', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1C),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _shareItinerary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isExporting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.ios_share),
                label: Text(_isExporting ? 'Generating...' : 'Share to Story', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ).animate().slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutQuart),
        ],
      ),
    );
  }
}
