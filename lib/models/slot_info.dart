class SlotInfo {
  final int slotIndex; // 0..12 (0-indexed internally)
  final bool isOccupied;
  final String? recipeUuid;
  final String recipeName;
  final int? crc;

  const SlotInfo({
    required this.slotIndex,
    this.isOccupied = false,
    this.recipeUuid,
    required this.recipeName,
    this.crc,
  });

  /// Display number for consumer UI (1..13)
  int get displayNumber => slotIndex + 1;

  SlotInfo copyWith({
    int? slotIndex,
    bool? isOccupied,
    String? recipeUuid,
    String? recipeName,
    int? crc,
  }) {
    return SlotInfo(
      slotIndex: slotIndex ?? this.slotIndex,
      isOccupied: isOccupied ?? this.isOccupied,
      recipeUuid: recipeUuid ?? this.recipeUuid,
      recipeName: recipeName ?? this.recipeName,
      crc: crc ?? this.crc,
    );
  }
}
