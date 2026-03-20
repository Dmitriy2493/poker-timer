// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blind_level.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlindLevelAdapter extends TypeAdapter<BlindLevel> {
  @override
  final int typeId = 0;

  @override
  BlindLevel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlindLevel(
      smallBlind: fields[0] as int,
      bigBlind: fields[1] as int,
      ante: fields[2] as int,
      durationMinutes: fields[3] as int,
      isBreak: fields[4] as bool,
      label: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BlindLevel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.smallBlind)
      ..writeByte(1)
      ..write(obj.bigBlind)
      ..writeByte(2)
      ..write(obj.ante)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.isBreak)
      ..writeByte(5)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlindLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
