import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'location_map_screen.dart';

class OfflineMapsScreen extends StatefulWidget {
  final String destination;
  
  const OfflineMapsScreen({super.key, required this.destination});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isDownloaded = false;

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) {
        setState(() {
          _progress = i / 100;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Map and Stays for ${widget.destination} saved offline! 🎉', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Offline Map & Stays', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[50],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _isDownloaded ? Icons.cloud_done : Icons.map_outlined,
                      size: 100,
                      color: _isDownloaded ? Colors.green : Colors.blue[400],
                    ).animate(target: _isDownloaded ? 1 : 0).scaleXY(end: 1.2, curve: Curves.elasticOut),
                    if (_isDownloading)
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[200],
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 40),
              Text(
                _isDownloaded 
                  ? 'Map Downloaded!' 
                  : 'Download ${widget.destination} Map',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _isDownloaded
                  ? 'You can now view your itinerary, booked stays, and local map without an internet connection.'
                  : 'Download the map, local recommendations, and your booked stays so you never get lost when offline.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!_isDownloaded)
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _startDownload,
                  icon: const Icon(Icons.download),
                  label: Text(
                    _isDownloading ? 'Downloading... ${( _progress * 100).toInt()}%' : 'Download Now',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              if (_isDownloaded)
                ElevatedButton.icon(
                  onPressed: () {
                    // Push LocationMapScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationMapScreen(
                          locationData: {
                            'name': widget.destination,
                            // Ideally, actual coords would be passed here if available
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map),
                  label: Text('Open Offline Map', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
