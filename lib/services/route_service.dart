import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/google_route.dart';
import '../models/route_request.dart';
import '../models/transit_segment.dart';
import '../models/transit_stop.dart';

class RouteService {
  static const String _apiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const String _url =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  static Future<List<GoogleRoute>> getRoutes(
    RouteRequest request,
  ) async {
    final requestBody = {
      'origin': {
        'address': request.origin,
      },
      'destination': {
        'address': request.destination,
      },
      'travelMode': 'TRANSIT',
      'computeAlternativeRoutes': request.computeAlternativeRoutes,
      'transitPreferences': {
        'routingPreference':
            request.transitPreference == TransitPreference.fewerTransfers
                ? 'FEWER_TRANSFERS'
                : 'LESS_WALKING',
      },
    };

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'routes.duration,'
            'routes.distanceMeters,'
            'routes.polyline.encodedPolyline,'
            'routes.legs.steps.navigationInstruction,'
            'routes.legs.steps.transitDetails',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Google Routes API error: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final routes = data['routes'] as List<dynamic>? ?? [];

    return routes
        .map(
          (route) => _parseRoute(
            route as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static GoogleRoute _parseRoute(
    Map<String, dynamic> route,
  ) {
    final durationString = route['duration'] as String? ?? '0s';

    final durationSeconds = int.tryParse(
          durationString.replaceAll('s', ''),
        ) ??
        0;

    final distanceMeters =
        (route['distanceMeters'] as num?)?.toInt() ?? 0;

    final encodedPolyline =
        (route['polyline']
                as Map<String, dynamic>?)?['encodedPolyline'] ??
            '';

    final transitSegments = <TransitSegment>[];

    final legs = route['legs'] as List<dynamic>? ?? [];

    for (final leg in legs) {
      final legMap = leg as Map<String, dynamic>;

      final steps = legMap['steps'] as List<dynamic>? ?? [];

      for (final step in steps) {
        final stepMap = step as Map<String, dynamic>;

        final transitDetails =
            stepMap['transitDetails'] as Map<String, dynamic>?;

        if (transitDetails == null) {
          continue;
        }

        transitSegments.add(
          _parseTransitSegment(transitDetails),
        );
      }
    }

    return GoogleRoute(
      duration: Duration(seconds: durationSeconds),
      distanceMeters: distanceMeters,
      encodedPolyline: encodedPolyline,
      transitSegments: transitSegments,
    );
  }

  static TransitSegment _parseTransitSegment(
    Map<String, dynamic> transitDetails,
  ) {
    final stopDetails =
        transitDetails['stopDetails'] as Map<String, dynamic>?;

    final transitLine =
        transitDetails['transitLine'] as Map<String, dynamic>?;

    final vehicle =
        transitLine?['vehicle'] as Map<String, dynamic>?;

    final vehicleType =
        vehicle?['type'] as String? ?? 'TRANSIT';

    final lineName =
        transitLine?['name'] as String? ?? 'Unknown line';

    final lineShortName =
        transitLine?['nameShort'] as String?;

    final headsign =
        transitDetails['headsign'] as String?;

    final stopCount =
        (transitDetails['stopCount'] as num?)?.toInt() ?? 0;

    return TransitSegment(
      vehicleType: vehicleType,
      lineName: lineName,
      lineShortName: lineShortName,
      headsign: headsign,
      departureStop: _parseStop(
        stopDetails?['departureStop'] as Map<String, dynamic>?,
        departureTime:
            stopDetails?['departureTime'] as String?,
      ),
      arrivalStop: _parseStop(
        stopDetails?['arrivalStop'] as Map<String, dynamic>?,
        arrivalTime:
            stopDetails?['arrivalTime'] as String?,
      ),
      stopCount: stopCount,
    );
  }

  static TransitStop? _parseStop(
    Map<String, dynamic>? stop,
    {
    String? departureTime,
    String? arrivalTime,
  }) {
    if (stop == null) {
      return null;
    }

    final name = stop['name'] as String? ?? 'Unknown stop';

    final location =
        stop['location'] as Map<String, dynamic>?;

    final latLng =
        location?['latLng'] as Map<String, dynamic>?;

    final latitude =
        (latLng?['latitude'] as num?)?.toDouble() ?? 0;

    final longitude =
        (latLng?['longitude'] as num?)?.toDouble() ?? 0;

    return TransitStop(
      name: name,
      latitude: latitude,
      longitude: longitude,
      departureTime: _parseDateTime(departureTime),
      arrivalTime: _parseDateTime(arrivalTime),
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}