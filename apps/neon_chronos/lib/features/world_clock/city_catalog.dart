/// Curated world cities with fixed UTC offsets (hours).
/// Offsets are standard (not DST-aware) — good enough for offline v2 prototype.
class WorldCity {
  const WorldCity({
    required this.id,
    required this.name,
    required this.region,
    required this.utcOffsetHours,
  });

  final String id;
  final String name;
  final String region;
  final double utcOffsetHours;

  DateTime at(DateTime utcNow) {
    return utcNow.toUtc().add(Duration(
          minutes: (utcOffsetHours * 60).round(),
        ));
  }

  String get offsetLabel {
    final sign = utcOffsetHours >= 0 ? '+' : '';
    final h = utcOffsetHours.truncate();
    final m = ((utcOffsetHours.abs() % 1) * 60).round();
    if (m == 0) return 'UTC$sign$h';
    return 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
  }
}

const kCityCatalog = <WorldCity>[
  WorldCity(id: 'los_angeles', name: 'Los Angeles', region: 'USA', utcOffsetHours: -8),
  WorldCity(id: 'new_york', name: 'New York', region: 'USA', utcOffsetHours: -5),
  WorldCity(id: 'chicago', name: 'Chicago', region: 'USA', utcOffsetHours: -6),
  WorldCity(id: 'denver', name: 'Denver', region: 'USA', utcOffsetHours: -7),
  WorldCity(id: 'sao_paulo', name: 'São Paulo', region: 'Brazil', utcOffsetHours: -3),
  WorldCity(id: 'london', name: 'London', region: 'UK', utcOffsetHours: 0),
  WorldCity(id: 'paris', name: 'Paris', region: 'France', utcOffsetHours: 1),
  WorldCity(id: 'berlin', name: 'Berlin', region: 'Germany', utcOffsetHours: 1),
  WorldCity(id: 'cairo', name: 'Cairo', region: 'Egypt', utcOffsetHours: 2),
  WorldCity(id: 'moscow', name: 'Moscow', region: 'Russia', utcOffsetHours: 3),
  WorldCity(id: 'dubai', name: 'Dubai', region: 'UAE', utcOffsetHours: 4),
  WorldCity(id: 'mumbai', name: 'Mumbai', region: 'India', utcOffsetHours: 5.5),
  WorldCity(id: 'bangkok', name: 'Bangkok', region: 'Thailand', utcOffsetHours: 7),
  WorldCity(id: 'singapore', name: 'Singapore', region: 'Singapore', utcOffsetHours: 8),
  WorldCity(id: 'hong_kong', name: 'Hong Kong', region: 'China', utcOffsetHours: 8),
  WorldCity(id: 'shanghai', name: 'Shanghai', region: 'China', utcOffsetHours: 8),
  WorldCity(id: 'tokyo', name: 'Tokyo', region: 'Japan', utcOffsetHours: 9),
  WorldCity(id: 'seoul', name: 'Seoul', region: 'Korea', utcOffsetHours: 9),
  WorldCity(id: 'sydney', name: 'Sydney', region: 'Australia', utcOffsetHours: 10),
  WorldCity(id: 'auckland', name: 'Auckland', region: 'NZ', utcOffsetHours: 12),
];

WorldCity? cityById(String id) {
  for (final c in kCityCatalog) {
    if (c.id == id) return c;
  }
  return null;
}

List<WorldCity> searchCities(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List.of(kCityCatalog);
  return kCityCatalog
      .where(
        (c) =>
            c.name.toLowerCase().contains(q) ||
            c.region.toLowerCase().contains(q) ||
            c.id.contains(q),
      )
      .toList();
}
