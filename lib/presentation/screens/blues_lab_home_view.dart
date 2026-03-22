import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:blues_lab/core/layout/responsive_breakpoints.dart';
import 'package:blues_lab/domain/utils/pair_grid_revision_sort.dart';
import 'package:blues_lab/presentation/cubits/pair_grids_cubit.dart';
import 'package:blues_lab/presentation/cubits/pair_grids_state.dart';
import 'package:blues_lab/presentation/sync_grid/sync_grid_hex_layout.dart';
import 'package:blues_lab/presentation/widgets/sync_grid_hex_stack.dart';

/// Home content: official `pairgrids.json` viewer (rendered inside [BluesLabMainShell]).
class BluesLabHomeView extends StatefulWidget {
  const BluesLabHomeView({super.key});

  @override
  State<BluesLabHomeView> createState() => _BluesLabHomeViewState();
}

class _BluesLabHomeViewState extends State<BluesLabHomeView> {
  final Set<int> _selectedTileIndices = {};
  String _pairFilter = '';
  /// 1–5: tiles with `cell.level <= this` are unlocked; bar shows levels 1…n lit.
  int _syncLevel = 3;
  /// 0–5; al bajar el sincro no puede superar ese nivel; 0 = sin gemas SA.
  int _awakeningLevel = 0;
  double _energyBudget = 24;
  bool _energyCap = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, inner) {
        return BlocConsumer<PairGridsCubit, PairGridsState>(
          listenWhen: (prev, curr) {
            if (curr is! PairGridsReady) return false;
            if (prev is! PairGridsReady) return true;
            return prev.selectedPairId != curr.selectedPairId;
          },
          listener: (context, state) {
            if (state is PairGridsReady) {
              setState(() {
                _selectedTileIndices.clear();
                if ((state.superAwakeningSkillByGridId[state.selectedPairId] ??
                        0) !=
                    0) {
                  _awakeningLevel = 0;
                }
              });
            }
          },
          builder: (context, state) {
            return switch (state) {
              PairGridsInitial() => const Center(child: Text('Preparing…')),
              PairGridsLoading() => const Center(
                  child: _LoadingNotice(),
                ),
              PairGridsFailure(:final error, :final stackTrace) => _ErrorPanel(
                  error: error,
                  stackTrace: stackTrace,
                  onRetry: () => context.read<PairGridsCubit>().load(),
                ),
              PairGridsReady() => _buildReady(
                  context,
                  state,
                  bodyWidth: inner.maxWidth,
                ),
            };
          },
        );
      },
    );
  }

  Widget _buildReady(
    BuildContext context,
    PairGridsReady s, {
    required double bodyWidth,
  }) {
    final cubit = context.read<PairGridsCubit>();
    final revisions = PairGridRevisionSort.byDateAscending(
      s.pairGrids[s.selectedPairId] ?? [],
    );
    final tiles = SyncGridHexLayout.tilesFromRevisions(revisions);
    final options = cubit.filteredPairIds(_pairFilter).toList();
    final awakeningSkillId =
        s.superAwakeningSkillByGridId[s.selectedPairId] ?? 0;
    final hasSuperAwakening = awakeningSkillId != 0;

    final sideBySide = bodyWidth >= 720;
    final controls = _buildControls(context, s, cubit, options);

    final grid = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FiveGemLevelBar(
                        level: _syncLevel,
                        onSelect: (n) => setState(() {
                          _syncLevel = n;
                          if (_awakeningLevel > n) {
                            _awakeningLevel = n;
                          }
                        }),
                        assetOn: 'assets/img/sync_level_on.png',
                        assetOff: 'assets/img/sync_level_off.png',
                        semanticsLabelBuilder: (slot) =>
                            'Sync move level $slot',
                      ),
                      if (hasSuperAwakening) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            height: 44,
                            child: VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                        ),
                        _FiveGemLevelBar(
                          level: _awakeningLevel,
                          onSelect: (n) => setState(() {
                            if (n == 1 && _awakeningLevel == 1) {
                              _awakeningLevel = 0;
                            } else {
                              if (_syncLevel < n) {
                                _syncLevel = n;
                              }
                              _awakeningLevel = n;
                            }
                          }),
                          assetOn: 'assets/img/awakening_level_on.png',
                          assetOff: 'assets/img/awakening_level_off.png',
                          semanticsLabelBuilder: (slot) =>
                              'Super awakening level $slot',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasSuperAwakening &&
                  _syncLevel == 5 &&
                  _awakeningLevel == 5 &&
                  awakeningSkillId != 0) ...[
                const SizedBox(height: 8),
                _SuperAwakeningPassiveCallout(
                  title: s.displayCatalog.skillName(awakeningSkillId) ??
                      'Habilidad $awakeningSkillId',
                  description:
                      s.displayCatalog.skillDescription(awakeningSkillId) ?? '',
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, inner) {
              return InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(120),
                minScale: 0.15,
                maxScale: 4,
                child: SyncGridHexStack(
                  tiles: tiles,
                  selected: _selectedTileIndices,
                  syncLevel: _syncLevel,
                  energyBudget: _energyBudget,
                  energyCap: _energyCap,
                  viewportSize: Size(inner.maxWidth, inner.maxHeight),
                  onTileToggle: (index) {
                    setState(() {
                      if (_selectedTileIndices.contains(index)) {
                        _selectedTileIndices.remove(index);
                      } else {
                        _selectedTileIndices.add(index);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    if (sideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: (bodyWidth * 0.34).clamp(260, 360),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: controls,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: grid),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 45,
          fit: FlexFit.tight,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: controls,
            ),
          ),
        ),
        const Divider(height: 1),
        Flexible(
          flex: 55,
          fit: FlexFit.tight,
          child: grid,
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    PairGridsReady s,
    PairGridsCubit cubit,
    List<String> options,
  ) {
    final listHeight = ResponsiveBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    )
        ? 120.0
        : 160.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Official data',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Filtrar (nombre o ID)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _pairFilter = v),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleccionado: ${s.displayCatalog.label(s.selectedPairId)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: listHeight,
            child: Material(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              child: Scrollbar(
                thumbVisibility: options.length > 6,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final id = options[index];
                    final selected = id == s.selectedPairId;
                    return ListTile(
                      dense: true,
                      title: Text(
                        s.displayCatalog.label(id),
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : null,
                        ),
                      ),
                      selected: selected,
                      onTap: () => cubit.selectPair(id),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Energy budget: ${_energyBudget.toStringAsFixed(1)}'),
          Slider(
            value: _energyBudget,
            min: 0,
            max: 40,
            onChanged: (v) => setState(() => _energyBudget = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dim tiles over energy budget'),
            value: _energyCap,
            onChanged: (v) => setState(() => _energyCap = v),
          ),
        ],
      ),
    );
  }
}

/// Pasiva adicional del compi con superdespertar al máximo (no añade nodos al grid).
class _SuperAwakeningPassiveCallout extends StatelessWidget {
  const _SuperAwakeningPassiveCallout({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(description, style: t.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Five level gems: tap [n] to set [level] to [n]; slots 1…[level] show [assetOn].
class _FiveGemLevelBar extends StatelessWidget {
  const _FiveGemLevelBar({
    required this.level,
    required this.onSelect,
    required this.assetOn,
    required this.assetOff,
    required this.semanticsLabelBuilder,
  });

  final int level;
  final ValueChanged<int> onSelect;
  final String assetOn;
  final String assetOff;
  final String Function(int slot) semanticsLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var slot = 1; slot <= 5; slot++) ...[
          if (slot > 1) const SizedBox(width: 6),
          _gem(slot),
        ],
      ],
    );
  }

  Widget _gem(int slot) {
    final lit = slot <= level;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onSelect(slot),
        customBorder: const CircleBorder(),
        child: Semantics(
          button: true,
          selected: lit,
          label: semanticsLabelBuilder(slot),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              lit ? assetOn : assetOff,
              width: 36,
              height: 36,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingNotice extends StatelessWidget {
  const _LoadingNotice();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading official pair grids…'),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'This may take a while (large JSON).',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load pair grids',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SelectableText(
              error.toString(),
              textAlign: TextAlign.center,
            ),
            if (stackTrace != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Stack trace (debug)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  child: SelectableText(
                    stackTrace.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
