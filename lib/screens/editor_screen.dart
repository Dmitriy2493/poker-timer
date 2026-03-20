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
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Structure' : 'Edit Structure'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Name field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: 'Structure Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _name = v,
            ),
          ),

          // Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_levels.length} levels',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  'Total: ${formatDuration(_levels.fold(0, (s, l) => s + l.durationMinutes))}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Levels list
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                return _LevelTile(
                  key: ValueKey('$index-${level.smallBlind}-${level.durationMinutes}'),
                  level: level,
                  index: index,
                  onEdit: () => _editLevel(index),
                  onDelete: () => setState(() => _levels.removeAt(index)),
                  onDuplicate: () => setState(() => _levels.insert(index + 1, level.copyWith())),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addBreak,
                  icon: const Icon(Icons.coffee),
                  label: const Text('Add Break'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _addLevel,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Level'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addLevel() {
    final last = _levels.lastWhere((l) => !l.isBreak, orElse: () =>
        BlindLevel(smallBlind: 25, bigBlind: 50, durationMinutes: 20));
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

class _LevelTile extends StatelessWidget {
  final BlindLevel level;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _LevelTile({
    super.key,
    required this.level,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: level.isBreak
              ? Colors.amber.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 12,
              color: level.isBreak
                  ? Colors.amber[800]
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          level.isBreak
              ? (level.label ?? 'Break')
              : '${formatChips(level.smallBlind)} / ${formatChips(level.bigBlind)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          level.isBreak
              ? '${level.durationMinutes} min'
              : '${level.durationMinutes} min${level.ante > 0 ? ' • Ante: ${formatChips(level.ante)}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (v) {
                if (v == 'duplicate') onDuplicate();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
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
  late TextEditingController _labelCtrl;
  late bool _isBreak;

  @override
  void initState() {
    super.initState();
    _isBreak = widget.level.isBreak;
    _sbCtrl = TextEditingController(text: widget.level.smallBlind.toString());
    _bbCtrl = TextEditingController(text: widget.level.bigBlind.toString());
    _anteCtrl = TextEditingController(text: widget.level.ante.toString());
    _durCtrl = TextEditingController(text: widget.level.durationMinutes.toString());
    _labelCtrl = TextEditingController(text: widget.level.label ?? '');
  }

  @override
  void dispose() {
    _sbCtrl.dispose();
    _bbCtrl.dispose();
    _anteCtrl.dispose();
    _durCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isBreak ? 'Edit Break' : 'Edit Level',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Is Break'),
            value: _isBreak,
            onChanged: (v) => setState(() => _isBreak = v),
          ),
          if (_isBreak) ...[
            _field('Label', _labelCtrl),
          ] else ...[
            Row(
              children: [
                Expanded(child: _numField('Small Blind', _sbCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _numField('Big Blind', _bbCtrl)),
              ],
            ),
            const SizedBox(height: 12),
            _numField('Ante (0 = none)', _anteCtrl),
          ],
          const SizedBox(height: 12),
          _numField('Duration (minutes)', _durCtrl),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: const Text('Save Level'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _numField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  void _save() {
    final updated = BlindLevel(
      smallBlind: int.tryParse(_sbCtrl.text) ?? 0,
      bigBlind: int.tryParse(_bbCtrl.text) ?? 0,
      ante: int.tryParse(_anteCtrl.text) ?? 0,
      durationMinutes: int.tryParse(_durCtrl.text) ?? 20,
      isBreak: _isBreak,
      label: _labelCtrl.text.isNotEmpty ? _labelCtrl.text : null,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }
}
