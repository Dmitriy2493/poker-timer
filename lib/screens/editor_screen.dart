import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/blind_level.dart';
import '../models/structure.dart';
import '../providers/tournament_provider.dart';
import '../utils/formatters.dart';

class EditorScreen extends StatefulWidget {
  final Structure structure;
  final bool isNew;

  const EditorScreen({super.key, required this.structure, required this.isNew});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late String _name;
  late List<BlindLevel> _levels;

  @override
  void initState() {
    super.initState();
    _name = widget.structure.name;
    _levels = widget.structure.levels.map((l) => l.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        leadingWidth: 80,
        title: Text(
          widget.isNew ? 'New Structure' : 'Edit Structure',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Name field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Name', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: TextEditingController(text: _name),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => _name = v,
                  ),
                ),
              ],
            ),
          ),

          // Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_levels.length} levels',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Total: ${formatDuration(_levels.fold(0, (s, l) => s + l.durationMinutes))}',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),

          // Levels list
          Expanded(
            child: _levels.isEmpty
                ? const Center(
                    child: Text(
                      'No levels yet.\nTap + to add.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _levels.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _levels.removeAt(oldIndex);
                        _levels.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final level = _levels[index];
                      return InkWell(
                        key: ValueKey('$index-${level.smallBlind}-${level.durationMinutes}'),
                        onTap: () => _editLevel(index),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          level.isBreak
                                              ? (level.label ?? 'Break')
                                              : 'Blinds: ${formatChips(level.smallBlind)}/${formatChips(level.bigBlind)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Level: ${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Time: ${level.durationMinutes}m',
                                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                                ],
                              ),
                            ),
                            const Divider(color: Colors.white12, height: 1, indent: 20, endIndent: 20),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white38),
                tooltip: 'Delete Last Level',
                onPressed: _levels.isNotEmpty
                    ? () => setState(() => _levels.removeLast())
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.coffee, color: Colors.amber),
                tooltip: 'Add Break',
                onPressed: _addBreak,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white70, size: 28),
                tooltip: 'Add Level',
                onPressed: _addLevel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addLevel() {
    final last = _levels.lastWhere((l) => !l.isBreak,
        orElse: () => BlindLevel(smallBlind: 25, bigBlind: 50, durationMinutes: 20));
    final newLevel = BlindLevel(
      smallBlind: (last.smallBlind * 1.5).round(),
      bigBlind: (last.bigBlind * 1.5).round(),
      ante: (last.ante * 1.5).round(),
      durationMinutes: last.durationMinutes,
    );
    setState(() => _levels.add(newLevel));
    _editLevel(_levels.length - 1);
  }

  void _addBreak() {
    setState(() => _levels.add(
          BlindLevel(smallBlind: 0, bigBlind: 0, durationMinutes: 15, isBreak: true, label: 'Break'),
        ));
  }

  void _editLevel(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _LevelEditSheet(
        level: _levels[index],
        onSave: (updated) {
          setState(() => _levels[index] = updated);
        },
      ),
    );
  }

  void _save() {
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }
    if (_levels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one level')),
      );
      return;
    }

    final updated = Structure(
      id: widget.structure.id,
      name: _name.trim(),
      levels: _levels,
      createdAt: widget.structure.createdAt,
    );

    final provider = context.read<TournamentProvider>();
    if (widget.isNew) {
      provider.addStructure(updated);
    } else {
      provider.updateStructure(updated);
    }
    Navigator.pop(context);
  }
}

class _LevelEditSheet extends StatefulWidget {
  final BlindLevel level;
  final ValueChanged<BlindLevel> onSave;

  const _LevelEditSheet({required this.level, required this.onSave});

  @override
  State<_LevelEditSheet> createState() => _LevelEditSheetState();
}

class _LevelEditSheetState extends State<_LevelEditSheet> {
  late TextEditingController _sbCtrl;
  late TextEditingController _bbCtrl;
  late TextEditingController _anteCtrl;
  late TextEditingController _durCtrl;
  late bool _isBreak;

  @override
  void initState() {
    super.initState();
    _isBreak = widget.level.isBreak;
    _sbCtrl = TextEditingController(text: widget.level.smallBlind.toString());
    _bbCtrl = TextEditingController(text: widget.level.bigBlind.toString());
    _anteCtrl = TextEditingController(text: widget.level.ante.toString());
    _durCtrl = TextEditingController(text: widget.level.durationMinutes.toString());
  }

  @override
  void dispose() {
    _sbCtrl.dispose();
    _bbCtrl.dispose();
    _anteCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              Expanded(
                child: Text(
                  _isBreak ? 'Edit Break' : 'Edit Blinds',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _save,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildField('Time', _durCtrl),
          const Divider(color: Colors.white12),

          // Break toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Break', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                Switch(
                  value: _isBreak,
                  onChanged: (v) => setState(() => _isBreak = v),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          if (!_isBreak) ...[
            _buildField('Small Blind', _sbCtrl),
            const Divider(color: Colors.white12),
            _buildField('Big Blind', _bbCtrl),
            const Divider(color: Colors.white12),
            _buildField('Ante', _anteCtrl),
            const Divider(color: Colors.white12),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final updated = BlindLevel(
      smallBlind: int.tryParse(_sbCtrl.text) ?? 0,
      bigBlind: int.tryParse(_bbCtrl.text) ?? 0,
      ante: int.tryParse(_anteCtrl.text) ?? 0,
      durationMinutes: int.tryParse(_durCtrl.text) ?? 20,
      isBreak: _isBreak,
      label: _isBreak ? 'Break' : null,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }
}
