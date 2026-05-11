// lib/data/models/relay_model.dart

class RelayModel {
  final int relayId;
  final bool state;
  final String lastChangedBy; // 'user' | 'schedule' | 'automation' | 'device'
  final DateTime? lastChangedAt;
  String name;    // internal name (e.g. 'Relay 1')
  String? label;  // user-defined appliance name (e.g. 'Living Room Light')

  RelayModel({
    required this.relayId,
    required this.state,
    this.lastChangedBy = 'user',
    this.lastChangedAt,
    String? name,
    this.label,
  }) : name = name ?? 'Relay $relayId';

  factory RelayModel.fromJson(Map<String, dynamic> json) {
    return RelayModel(
      relayId: json['relayId'] ?? 1,
      state: json['state'] ?? false,
      lastChangedBy: json['lastChangedBy'] ?? 'user',
      lastChangedAt: json['lastChangedAt'] != null
          ? DateTime.tryParse(json['lastChangedAt'])
          : null,
      label: json['label'] as String?,
    );
  }

  RelayModel copyWith({bool? state, String? lastChangedBy, String? label}) {
    return RelayModel(
      relayId: relayId,
      state: state ?? this.state,
      lastChangedBy: lastChangedBy ?? this.lastChangedBy,
      lastChangedAt: DateTime.now(),
      name: name,
      label: label ?? this.label,
    );
  }

  // Default 4 relays
  static List<RelayModel> defaultRelays() {
    return List.generate(4, (i) => RelayModel(relayId: i + 1, state: false));
  }
}
