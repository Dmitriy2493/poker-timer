import 'dart:convert';
import 'package:hive/hive.dart';
import 'blind_level.dart';

part 'structure.g.dart';

@HiveType(typeId: 1)
class Structure extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<BlindLevel> levels;

  @HiveField(3)
  DateTime createdAt;

  Structure({
    required this.id,
    required this.name,
    required this.levels,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'levels': levels.map((l) => l.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Structure.fromJson(Map<String, dynamic> json) => Structure(
        id: json['id'] as String,
        name: json['name'] as String,
        levels: (json['levels'] as List)
            .map((l) => BlindLevel.fromJson(l as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory Structure.fromJsonString(String jsonString) =>
      Structure.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  int get totalDurationMinutes =>
      levels.fold(0, (sum, l) => sum + l.durationMinutes);

  static Structure defaultStructure() {
    return Structure(
      id: 'default',
      name: 'Standard Tournament',
      createdAt: DateTime.now(),
      levels: [
        BlindLevel(smallBlind: 25, bigBlind: 50, ante: 0, durationMinutes: 20),
        BlindLevel(smallBlind: 50, bigBlind: 100, ante: 0, durationMinutes: 20),
        BlindLevel(smallBlind: 75, bigBlind: 150, ante: 0, durationMinutes: 20),
        BlindLevel(smallBlind: 100, bigBlind: 200, ante: 25, durationMinutes: 20),
        BlindLevel(smallBlind: 0, bigBlind: 0, ante: 0, durationMinutes: 15, isBreak: true, label: 'Break'),
        BlindLevel(smallBlind: 150, bigBlind: 300, ante: 25, durationMinutes: 20),
        BlindLevel(smallBlind: 200, bigBlind: 400, ante: 50, durationMinutes: 20),
        BlindLevel(smallBlind: 300, bigBlind: 600, ante: 75, durationMinutes: 20),
        BlindLevel(smallBlind: 400, bigBlind: 800, ante: 100, durationMinutes: 20),
        BlindLevel(smallBlind: 0, bigBlind: 0, ante: 0, durationMinutes: 15, isBreak: true, label: 'Break'),
        BlindLevel(smallBlind: 500, bigBlind: 1000, ante: 100, durationMinutes: 20),
        BlindLevel(smallBlind: 600, bigBlind: 1200, ante: 200, durationMinutes: 20),
        BlindLevel(smallBlind: 800, bigBlind: 1600, ante: 200, durationMinutes: 20),
        BlindLevel(smallBlind: 1000, bigBlind: 2000, ante: 300, durationMinutes: 20),
      ],
    );
  }
}
