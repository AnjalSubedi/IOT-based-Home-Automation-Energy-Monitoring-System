// lib/data/models/energy_reading_model.dart

class EnergyReading {
  final double voltage;
  final double current;
  final double power;
  final double frequency;
  final double powerFactor;
  final DateTime timestamp;

  EnergyReading({
    required this.voltage,
    required this.current,
    required this.power,
    required this.frequency,
    required this.powerFactor,
    required this.timestamp,
  });

  factory EnergyReading.fromJson(Map<String, dynamic> json) {
    return EnergyReading(
      voltage: (json['voltage'] ?? 0).toDouble(),
      current: (json['current'] ?? 0).toDouble(),
      power: (json['power'] ?? 0).toDouble(),
      frequency: (json['frequency'] ?? 50).toDouble(),
      powerFactor: (json['powerFactor'] ?? 1).toDouble(),
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // For live Socket.IO data (no 'createdAt' field)
  factory EnergyReading.fromLive(Map<String, dynamic> json) {
    return EnergyReading(
      voltage: (json['voltage'] ?? 0).toDouble(),
      current: (json['current'] ?? 0).toDouble(),
      power: (json['power'] ?? 0).toDouble(),
      frequency: (json['frequency'] ?? 50).toDouble(),
      powerFactor: (json['powerFactor'] ?? 1).toDouble(),
      timestamp: DateTime.now(),
    );
  }
}

class EnergySummary {
  final double totalKWh;
  final double avgPower;
  final double peakPower;
  final double estimatedCost;
  final String currency;
  final String period;
  final int readingCount;

  EnergySummary({
    required this.totalKWh,
    required this.avgPower,
    required this.peakPower,
    required this.estimatedCost,
    required this.currency,
    required this.period,
    required this.readingCount,
  });

  factory EnergySummary.fromJson(Map<String, dynamic> json) {
    return EnergySummary(
      totalKWh: (json['totalKWh'] ?? 0).toDouble(),
      avgPower: (json['avgPower'] ?? 0).toDouble(),
      peakPower: (json['peakPower'] ?? 0).toDouble(),
      estimatedCost: (json['estimatedCost'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NPR',
      period: json['period'] ?? 'today',
      readingCount: json['readingCount'] ?? 0,
    );
  }

  factory EnergySummary.empty() => EnergySummary(
    totalKWh: 0, avgPower: 0, peakPower: 0,
    estimatedCost: 0, currency: 'NPR',
    period: 'today', readingCount: 0,
  );
}
