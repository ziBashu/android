import 'dart:convert';
import 'dart:io';

/// Open-Meteo current conditions (no API key).
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.weatherCode,
    required this.condition,
    this.windKmh,
    this.place,
    this.latitude,
    this.longitude,
  });

  final double temperatureC;
  final int weatherCode;
  final String condition;
  final double? windKmh;
  final String? place;
  final double? latitude;
  final double? longitude;

  String get tempLabel => '${temperatureC.round()}°';

  WeatherSnapshot copyWith({String? place}) {
    return WeatherSnapshot(
      temperatureC: temperatureC,
      weatherCode: weatherCode,
      condition: condition,
      windKmh: windKmh,
      place: place ?? this.place,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static WeatherSnapshot? fromOpenMeteo(
    Map<String, dynamic> json, {
    String? place,
    double? latitude,
    double? longitude,
  }) {
    final current = json['current'];
    if (current is! Map) return null;
    final map = Map<String, dynamic>.from(current);
    final temp = (map['temperature_2m'] as num?)?.toDouble();
    if (temp == null) return null;
    final code = (map['weather_code'] as num?)?.toInt() ?? 0;
    final wind = (map['wind_speed_10m'] as num?)?.toDouble();
    return WeatherSnapshot(
      temperatureC: temp,
      weatherCode: code,
      condition: conditionForCode(code),
      windKmh: wind,
      place: place,
      latitude: latitude ?? (json['latitude'] as num?)?.toDouble(),
      longitude: longitude ?? (json['longitude'] as num?)?.toDouble(),
    );
  }

  static String conditionForCode(int code) {
    if (code == 0) return 'Clear';
    if (code == 1) return 'Mainly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 85 && code <= 86) return 'Snow showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Weather';
  }
}

class WeatherService {
  WeatherService._();

  static Future<WeatherSnapshot?> fetch({
    required double latitude,
    required double longitude,
    String? place,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current': 'temperature_2m,weather_code,wind_speed_10m',
      'timezone': 'auto',
    });
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      return WeatherSnapshot.fromOpenMeteo(
        Map<String, dynamic>.from(decoded),
        place: place,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
