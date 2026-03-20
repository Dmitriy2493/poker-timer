import 'package:hive/hive.dart';

part 'blind_level.g.dart';

@HiveType(typeId: 0)
class BlindLevel extends HiveObject {
  @HiveField(0)
  int smallBlind;

  @HiveField(1)
  int bigBlind;

  @HiveField(2)
  int ante;

  @HiveField(3)
  int durationMinutes;

  @HiveField(4)
  bool isBreak;

  @HiveField(5)
  String? label;

  BlindLevel({
    required this.smallBlind,
    required this.bigBlind,
    this.ante = 0,
    required this.durationMinutes,
    this.isBreak = false,
    this.label,
  });

  BlindLevel copyWith({
    int? smallBlind,
    int? bigBlind,
    int? ante,
    int? durationMinutes,
    bool? isBreak,
    String? label,
  }) {
    return BlindLevel(
      smallBlind: smallBlind ?? this.smallBlind,
      bigBlind: bigBlind ?? this.bigBlind,
      ante: ante ?? this.ante,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isBreak: isBreak ?? this.isBreak,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
        'smallBlind': smallBlind,
        'bigBlind': bigBlind,
        'ante': ante,
        'durationMinutes': durationMinutes,
        'isBreak': isBreak,
        'label': label,
      };

  factory BlindLevel.fromJson(Map<String, dynamic> json) => BlindLevel(
        smallBlind: json['smallBlind'] as int,
        bigBlind: json['bigBlind'] as int,
        ante: json['ante'] as int? ?? 0,
        durationMinutes: json['durationMinutes'] as int,
        isBreak: json['isBreak'] as bool? ?? false,
        label: json['label'] as String?,
      );

  String get displayName {
    if (isBreak) return label ?? 'Break';
    return label ?? '$smallBlind / $bigBlind';
  }
}
