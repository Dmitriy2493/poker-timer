import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../models/structure.dart';
import '../models/blind_level.dart';
import '../utils/formatters.dart';
import 'timer_screen.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        final structure = provider.activeStructure;
        final levels = structure?.levels ?? [];
        final hasStructure = structure != null && levels.isNotEmpty;

        // If no active structure with levels, show the welcome/start screen
        if (!hasStructure) {
          return _buildStartScreen(context, provider);
        }

        // Show blind levels list
        return _buildLevelsScreen(context, provider, structure, levels);
      },
    );
  }

  Widget _buildStartScreen(BuildContext context, TournamentProvider provider) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Poker Timer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/poker_cards.png',
              width: 160,
              height: 130,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 280,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showTournamentOptions(context, provider),
                child: const Text(
                  'Start New Tournament',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTournamentOptions(BuildContext context, TournamentProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Tournament Type',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.casino, color: Colors.white54),
              title: const Text('Standard Tournament', style: TextStyle(color: Colors.white)),
              subtitle: const Text('17-level predefined structure', style: TextStyle(color: Colors.white38)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () {
                Navigator.pop(ctx);
                _addDefaultStructure(context, provider);
              },
            ),
            const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.white54),
              title: const Text('Custom Tournament', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Create your own blind structure', style: TextStyle(color: Colors.white38)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () {
                Navigator.pop(ctx);
                _createCustomStructure(context, provider);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelsScreen(
    BuildContext context,
    TournamentProvider provider,
    Structure structure,
    List<BlindLevel> levels,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () {
            // Go back to start screen by deselecting
            provider.selectStructure(Structure(
              id: '__none__',
              name: '',
              levels: [],
              createdAt: DateTime.now(),
            ));
          },
        ),
        title: Text(
          structure.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: levels.length,
        separatorBuilder: (context, index) =>
            const Divider(color: Colors.white12, height: 1, indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final level = levels[index];
          return InkWell(
            onTap: () => _editLevel(context, provider, structure, index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.isBreak
                              ? level.label ?? 'Break'
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
                          style: const TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Time: ${level.durationMinutes}m',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimerScreen()),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white38),
                tooltip: 'Delete Structure',
                onPressed: () => _confirmDelete(context, provider, structure),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white70, size: 28),
                tooltip: 'Add Level',
                onPressed: () => _addLevel(context, provider, structure),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editLevel(BuildContext context, TournamentProvider provider, Structure structure, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _QuickEditSheet(
        level: structure.levels[index],
        onSave: (updated) {
          final newLevels = List.of(structure.levels);
          newLevels[index] = updated;
          final newStructure = Structure(
            id: structure.id,
            name: structure.name,
            levels: newLevels,
            createdAt: structure.createdAt,
          );
          provider.updateStructure(newStructure);
        },
        onDelete: () {
          final newLevels = List.of(structure.levels);
          newLevels.removeAt(index);
          final newStructure = Structure(
            id: structure.id,
            name: structure.name,
            levels: newLevels,
            createdAt: structure.createdAt,
          );
          provider.updateStructure(newStructure);
        },
      ),
    );
  }

  void _addLevel(BuildContext context, TournamentProvider provider, Structure structure) {
    final levels = structure.levels;
    final last = levels.isNotEmpty
        ? levels.lastWhere((l) => !l.isBreak,
            orElse: () => BlindLevel(smallBlind: 25, bigBlind: 50, durationMinutes: 20))
        : BlindLevel(smallBlind: 25, bigBlind: 50, durationMinutes: 20);
    final newLevel = BlindLevel(
      smallBlind: (last.smallBlind * 1.5).round(),
      bigBlind: (last.bigBlind * 1.5).round(),
      ante: (last.ante * 1.5).round(),
      durationMinutes: last.durationMinutes,
    );
    final newLevels = List.of(levels)..add(newLevel);
    final newStructure = Structure(
      id: structure.id,
      name: structure.name,
      levels: newLevels,
      createdAt: structure.createdAt,
    );
    provider.updateStructure(newStructure);
  }

  void _confirmDelete(BuildContext context, TournamentProvider provider, Structure structure) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Structure'),
        content: Text('Delete "${structure.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteStructure(structure.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addDefaultStructure(BuildContext context, TournamentProvider provider) {
    final defaultStructure = Structure.defaultStructure();
    final structure = Structure(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: defaultStructure.name,
      levels: defaultStructure.levels,
      createdAt: DateTime.now(),
    );
    provider.addStructure(structure);
    provider.selectStructure(structure);
  }

  void _createCustomStructure(BuildContext context, TournamentProvider provider) {
    final newStructure = Structure(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Custom Tournament',
      createdAt: DateTime.now(),
      levels: [],
    );
    provider.addStructure(newStructure);
    // Open editor for custom so they can add levels
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorScreen(structure: newStructure, isNew: false)),
    );
  }
}

class _QuickEditSheet extends StatefulWidget {
  final BlindLevel level;
  final ValueChanged<BlindLevel> onSave;
  final VoidCallback onDelete;

  const _QuickEditSheet({
    required this.level,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_QuickEditSheet> createState() => _QuickEditSheetState();
}

class _QuickEditSheetState extends State<_QuickEditSheet> {
  late TextEditingController _sbCtrl;
  late TextEditingController _bbCtrl;
  late TextEditingController _durCtrl;
  late bool _isBreak;

  @override
  void initState() {
    super.initState();
    _isBreak = widget.level.isBreak;
    _sbCtrl = TextEditingController(text: widget.level.smallBlind.toString());
    _bbCtrl = TextEditingController(text: widget.level.bigBlind.toString());
    _durCtrl = TextEditingController(text: widget.level.durationMinutes.toString());
  }

  @override
  void dispose() {
    _sbCtrl.dispose();
    _bbCtrl.dispose();
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
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              const Expanded(
                child: Text(
                  'Edit Blinds',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: _save,
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildField('Time', _durCtrl),
          const Divider(color: Colors.white12),
          Row(
            children: [
              const Expanded(child: Text('Break', style: TextStyle(color: Colors.white, fontSize: 16))),
              Switch(
                value: _isBreak,
                activeTrackColor: Colors.white54,
                activeThumbColor: Colors.white,
                onChanged: (v) => setState(() => _isBreak = v),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          if (!_isBreak) ...[
            _buildField('Small Blind', _sbCtrl),
            const Divider(color: Colors.white12),
            _buildField('Big Blind', _bbCtrl),
            const Divider(color: Colors.white12),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                widget.onDelete();
                Navigator.pop(context);
              },
              child: const Text('Delete Level', style: TextStyle(color: Colors.red)),
            ),
          ),
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
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16))),
          SizedBox(
            width: 100,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
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
      ante: widget.level.ante,
      durationMinutes: int.tryParse(_durCtrl.text) ?? 20,
      isBreak: _isBreak,
      label: _isBreak ? 'Break' : null,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }
}
