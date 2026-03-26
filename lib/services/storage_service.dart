import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/structure.dart';

class StorageService {
  static const _boxName = 'structures';
  late Box<Map> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<List<Structure>> loadStructures() async {
    final structures = <Structure>[];
    for (final v in _box.values) {
      try {
        structures.add(Structure.fromJson(Map<String, dynamic>.from(v)));
      } catch (_) {
        // Skip corrupt entries
      }
    }
    return structures;
  }

  Future<void> saveStructure(Structure structure) async {
    await _box.put(structure.id, structure.toJson());
  }

  Future<void> deleteStructure(String id) async {
    await _box.delete(id);
  }

  Future<String> exportStructure(Structure structure) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${structure.name.replaceAll(' ', '_')}.poker');
    await file.writeAsString(structure.toJsonString());
    return file.path;
  }

  Future<Structure?> importStructure(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      final structure = Structure.fromJsonString(contents);
      // Give it a new id to avoid collision
      final imported = Structure(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: structure.name,
        levels: structure.levels,
        createdAt: DateTime.now(),
      );
      await saveStructure(imported);
      return imported;
    } catch (_) {
      return null;
    }
  }
}
