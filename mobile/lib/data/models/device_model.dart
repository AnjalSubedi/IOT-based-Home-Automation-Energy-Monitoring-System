// lib/data/models/device_model.dart

class DeviceModel {
  final String deviceId;
  final String name;
  final String location;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final double? powerThreshold;

  DeviceModel({
    required this.deviceId,
    required this.name,
    required this.location,
    required this.isOnline,
    this.lastSeenAt,
    this.powerThreshold,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['deviceId'] ?? '',
      name: json['name'] ?? 'Unknown Device',
      location: json['location'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'])
          : null,
      powerThreshold: json['powerThreshold']?.toDouble(),
    );
  }

  DeviceModel copyWith({bool? isOnline, DateTime? lastSeenAt}) {
    return DeviceModel(
      deviceId: deviceId,
      name: name,
      location: location,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      powerThreshold: powerThreshold,
    );
  }
}
