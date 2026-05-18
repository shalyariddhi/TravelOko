import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip.dart';
import 'package:flutter/foundation.dart';

class CalendarService {
  /// Exports the trip as a multi-event ICS file.
  static Future<void> exportTripToICS(Trip trip) async {
    try {
      String events = '';

      if (trip.itineraries.isNotEmpty) {
        // Generate a multi-event ICS, scheduling activities throughout the days
        DateTime currentSlot = DateTime.utc(
          trip.startDate.year,
          trip.startDate.month,
          trip.startDate.day,
          9, // Start at 9 AM
          0,
        );

        for (var i = 0; i < trip.itineraries.length; i++) {
          final item = trip.itineraries[i];
          final start = currentSlot;
          final end = currentSlot.add(const Duration(hours: 3));

          events += '''
BEGIN:VEVENT
UID:${trip.id}_$i@GoTrivo.app
DTSTAMP:${_formatDate(DateTime.now())}
DTSTART:${_formatDate(start)}
DTEND:${_formatDate(end)}
SUMMARY:${item.title}
DESCRIPTION:${item.description}
LOCATION:${trip.destination}
BEGIN:VALARM
TRIGGER:-P1D
ACTION:DISPLAY
DESCRIPTION:Trip Tomorrow: ${item.title}
END:VALARM
BEGIN:VALARM
TRIGGER:-PT2H
ACTION:DISPLAY
DESCRIPTION:Trip Reminder: ${item.title}
END:VALARM
END:VEVENT
''';
          // Move to next slot (+4 hours). If past 8 PM, move to next day 9 AM
          currentSlot = currentSlot.add(const Duration(hours: 4));
          if (currentSlot.hour >= 20) {
            currentSlot = DateTime.utc(currentSlot.year, currentSlot.month, currentSlot.day + 1, 9, 0);
          }
        }
      } else {
        // Fallback: Single giant event if no itinerary items exist
        final endDate = trip.startDate.add(Duration(days: trip.durationDays));
        events = '''
BEGIN:VEVENT
UID:${trip.id}@GoTrivo.app
DTSTAMP:${_formatDate(DateTime.now())}
DTSTART:${_formatDate(trip.startDate)}
DTEND:${_formatDate(endDate)}
SUMMARY:${trip.title}
DESCRIPTION:${trip.description}
LOCATION:${trip.destination}
BEGIN:VALARM
TRIGGER:-P1D
ACTION:DISPLAY
DESCRIPTION:Trip Tomorrow: ${trip.title}
END:VALARM
BEGIN:VALARM
TRIGGER:-PT2H
ACTION:DISPLAY
DESCRIPTION:Trip Reminder: ${trip.title}
END:VALARM
END:VEVENT
''';
      }

      final content = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Go-Trivo//EN
$events
END:VCALENDAR
''';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/trip_${trip.id}.ics');
      await file.writeAsString(content);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Trip Calendar Export',
      );
    } catch (e) {
      debugPrint("Error exporting ICS: $e");
      // Fallback to web if ICS generation fails
      await exportTripToGoogleWeb(trip);
    }
  }

  /// Opens Google Calendar in the browser. Used as a secondary option.
  static Future<void> exportTripToGoogleWeb(Trip trip) async {
    try {
      final endDate = trip.startDate.add(Duration(days: trip.durationDays));
      final startFormatted = _formatDate(trip.startDate);
      final endFormatted = _formatDate(endDate);

      final url = 'https://calendar.google.com/calendar/render'
          '?action=TEMPLATE'
          '&text=${Uri.encodeComponent(trip.title)}'
          '&details=${Uri.encodeComponent(trip.description)}'
          '&location=${Uri.encodeComponent(trip.destination)}'
          '&dates=$startFormatted/$endFormatted';

      final uri = Uri.parse(url);

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("Error exporting to Google Web: $e");
    }
  }

  /// Always stores and returns dates in UTC format required by ICS/Google.
  static String _formatDate(DateTime dt) {
    return dt.toUtc()
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first +
        'Z';
  }
}

