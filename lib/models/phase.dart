class Phase {
  final int speed; // 300 - 4000 RPM
  final int accel; // 50 - 2000
  final int temp; // 0 - 70 °C (0 = heater off)
  final int duration; // 0 - 240 seconds

  const Phase({
    required this.speed,
    required this.accel,
    required this.temp,
    required this.duration,
  });

  /// Factory constructor ensuring hardware-safe bounded values
  factory Phase.clamped({
    int speed = 3000,
    int accel = 800,
    int temp = 65,
    int duration = 30,
  }) {
    return Phase(
      speed: speed.clamp(300, 4000),
      accel: accel.clamp(50, 2000),
      temp: temp.clamp(0, 70),
      duration: duration.clamp(0, 240),
    );
  }

  bool get isCold => temp == 0;
  bool get isActive => duration > 0;

  Phase copyWith({
    int? speed,
    int? accel,
    int? temp,
    int? duration,
  }) {
    return Phase.clamped(
      speed: speed ?? this.speed,
      accel: accel ?? this.accel,
      temp: temp ?? this.temp,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'accel': accel,
        'temp': temp,
        'duration': duration,
      };

  factory Phase.fromJson(Map<String, dynamic> json) {
    return Phase.clamped(
      speed: (json['speed'] as num?)?.toInt() ?? 3000,
      accel: (json['accel'] as num?)?.toInt() ?? 800,
      temp: (json['temp'] as num?)?.toInt() ?? 65,
      duration: (json['duration'] as num?)?.toInt() ?? 30,
    );
  }

  @override
  String toString() =>
      'Phase(${duration}s @ $speed RPM, $temp°C, accel $accel)';
}
