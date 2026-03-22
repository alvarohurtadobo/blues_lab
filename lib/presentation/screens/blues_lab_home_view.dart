import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:blues_lab/core/layout/responsive_breakpoints.dart';
import 'package:blues_lab/domain/entities/pair_grid_revision.dart';
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
  double _syncLevel = 3;
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
            return prev.selectedPairId != curr.selectedPairId ||
                prev.selectedRevisionIndex != curr.selectedRevisionIndex;
          },
          listener: (context, state) {
            if (state is PairGridsReady) {
              setState(() => _selectedTileIndices.clear());
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
    final revisions = cubit.sortedRevisionsFor(s);
    final safeRevisionIndex =
        s.selectedRevisionIndex.clamp(0, revisions.length - 1);
    final revision = revisions[safeRevisionIndex];
    final tiles = SyncGridHexLayout.tilesFromRevision(revision);
    final options = cubit.filteredPairIds(_pairFilter).toList();

    final sideBySide = bodyWidth >= 720;
    final controls = _buildControls(
      context,
      s,
      revisions,
      safeRevisionIndex,
      cubit,
      options,
    );

    final grid = LayoutBuilder(
      builder: (context, inner) {
        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(120),
          minScale: 0.15,
          maxScale: 4,
          child: SyncGridHexStack(
            tiles: tiles,
            selected: _selectedTileIndices,
            syncLevel: _syncLevel.round(),
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
    List<PairGridRevision> revisions,
    int safeRevisionIndex,
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
              labelText: 'Filter pair ids',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _pairFilter = v),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${s.selectedPairId}',
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
                        id,
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
          const SizedBox(height: 12),
          Text(
            'Revision (${revisions.length} total)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: safeRevisionIndex,
                items: [
                  for (var i = 0; i < revisions.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        _revisionLabel(revisions[i], i),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (i) {
                  if (i != null) cubit.selectRevisionIndex(i);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sync level: ${_syncLevel.round()}'),
          Slider(
            value: _syncLevel,
            min: 1,
            max: 5,
            divisions: 4,
            label: '${_syncLevel.round()}',
            onChanged: (v) => setState(() => _syncLevel = v),
          ),
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

  static String _revisionLabel(PairGridRevision r, int index) {
    final n = index + 1;
    if (r.date == 0) {
      return 'Revision $n (base · date 0)';
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(r.date * 1000, isUtc: true);
    return 'Revision $n · ${dt.toIso8601String().split('T').first} (UTC)';
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
