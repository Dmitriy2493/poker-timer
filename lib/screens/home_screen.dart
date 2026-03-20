import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../models/structure.dart';
import '../utils/formatters.dart';
import 'timer_screen.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Active structure selector
              if (provider.activeStructure != null)
                _ActiveStructureCard(provider: provider),
              const SizedBox(height: 8),
              // Structures list
              Expanded(
                child: provider.structures.isEmpty
                    ? const _EmptyState()
                    : _StructureList(provider: provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createStructure(context),
        icon: const Icon(Icons.add),
        label: const Text('New Structure'),
      ),
    );
  }

  void _createStructure(BuildContext context) {
    final newStructure = Structure(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'New Tournament',
      createdAt: DateTime.now(),
      levels: [],
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorScreen(structure: newStructure, isNew: true)),
    );
  }
}

class _ActiveStructureCard extends StatelessWidget {
  final TournamentProvider provider;

  const _ActiveStructureCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final structure = provider.activeStructure!;
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimerScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      structure.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TimerScreen()),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${structure.levels.length} levels • ${formatDuration(structure.totalDurationMinutes)} total',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StructureList extends StatelessWidget {
  final TournamentProvider provider;

  const _StructureList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.structures.length,
      itemBuilder: (context, index) {
        final structure = provider.structures[index];
        final isActive = provider.activeStructure?.id == structure.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              structure.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${structure.levels.length} levels • ${formatDuration(structure.totalDurationMinutes)}',
            ),
            leading: CircleAvatar(
              backgroundColor: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.casino,
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'select', child: Text('Select')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) => _handleAction(context, value, structure, provider),
            ),
            onTap: () {
              provider.selectStructure(structure);
            },
          ),
        );
      },
    );
  }

  void _handleAction(
    BuildContext context,
    String action,
    Structure structure,
    TournamentProvider provider,
  ) {
    switch (action) {
      case 'select':
        provider.selectStructure(structure);
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditorScreen(structure: structure, isNew: false),
          ),
        );
      case 'delete':
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
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.casino_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No structures yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a blind structure',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
          ),
        ],
      ),
    );
  }
}
