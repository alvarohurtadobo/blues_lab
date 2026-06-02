import 'package:flutter/material.dart';

import '../../data/sync_pair_repository.dart';
import '../../models/sync_pair_models.dart';
import '../../widgets/hex_grid.dart';
import '../calculator/calculator_panel.dart';
import '../overview/overview_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _repository = SyncPairRepository();

  late final Future<ParsedData> _dataFuture = _repository.load();
  int _selectedPairIndex = 0;
  final Set<int> _activeCells = <int>{};
  bool _hardCap = true;
  int _moveLevel = 5;
  int _rightTab = 1;
  bool _initialActivationDone = false;
  bool _expandedRight = false;

  static const _hexDirections = [
    [1, 0, -1],
    [-1, 0, 1],
    [0, 1, -1],
    [0, -1, 1],
    [1, -1, 0],
    [-1, 1, 0],
  ];

  bool _isAdjacentToCenter(GridCellData cell) {
    for (final d in _hexDirections) {
      if (cell.q == d[0] && cell.r == d[1] && cell.s == d[2]) return true;
    }
    return false;
  }

  bool _isAdjacentToActiveOrCenter(
    GridCellData cell,
    List<GridCellData> allCells,
  ) {
    for (final d in _hexDirections) {
      final nq = cell.q + d[0];
      final nr = cell.r + d[1];
      final ns = cell.s + d[2];
      if (nq == 0 && nr == 0 && ns == 0) return true;
      for (final other in allCells) {
        if (other.q == nq &&
            other.r == nr &&
            other.s == ns &&
            _activeCells.contains(other.cellNumber)) {
          return true;
        }
      }
    }
    return false;
  }

  void _pruneDisconnected(List<GridCellData> allCells) {
    final cellMap = <String, GridCellData>{};
    for (final c in allCells) {
      cellMap['${c.q},${c.r},${c.s}'] = c;
    }
    final connected = <int>{};
    final queue = <List<int>>[
      [0, 0, 0],
    ];
    final visited = <String>{'0,0,0'};
    while (queue.isNotEmpty) {
      final pos = queue.removeAt(0);
      for (final d in _hexDirections) {
        final nq = pos[0] + d[0];
        final nr = pos[1] + d[1];
        final ns = pos[2] + d[2];
        final key = '$nq,$nr,$ns';
        if (visited.contains(key)) continue;
        visited.add(key);
        final neighbor = cellMap[key];
        if (neighbor != null && _activeCells.contains(neighbor.cellNumber)) {
          connected.add(neighbor.cellNumber);
          queue.add([nq, nr, ns]);
        }
      }
    }
    _activeCells.retainAll(connected);
  }

  void _activateFreeCenterCells(List<GridCellData> cells) {
    for (final cell in cells) {
      if (cell.energyCost == 0 &&
          cell.moveLevel <= _moveLevel.clamp(1, 5) &&
          _isAdjacentToCenter(cell)) {
        _activeCells.add(cell.cellNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<ParsedData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error cargando datos: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data!;
          if (data.pairs.isEmpty) {
            return const Center(child: Text('No se encontraron personajes.'));
          }

          final selectedPair = data.pairs[_selectedPairIndex];

          if (_hardCap && !_initialActivationDone) {
            _initialActivationDone = true;
            _activateFreeCenterCells(selectedPair.cells);
          }

          final selectedEnergy =
              60 -
              selectedPair.cells
                  .where((c) => _activeCells.contains(c.cellNumber))
                  .fold<int>(0, (sum, c) => sum + c.energyCost);
          final selectedOrbs = selectedPair.cells
              .where((c) => _activeCells.contains(c.cellNumber))
              .fold<int>(0, (sum, c) => sum + c.orbCost);

          return Row(
            children: [
              Expanded(
                flex: _expandedRight ? 2 : 5,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('⚡ $selectedEnergy'),
                            const SizedBox(width: 12),
                            Text('🔮 $selectedOrbs'),
                            const SizedBox(width: 16),
                            for (int i = 1; i <= 5; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _moveLevel = i;
                                      _activeCells.removeWhere((cn) {
                                        final cell = selectedPair.cells
                                            .firstWhere(
                                              (c) => c.cellNumber == cn,
                                            );
                                        return cell.moveLevel > i.clamp(1, 5);
                                      });
                                      if (_hardCap) {
                                        _pruneDisconnected(selectedPair.cells);
                                      }
                                    });
                                  },
                                  child: Image.asset(
                                    _moveLevel >= i
                                        ? 'assets/img/sync_level_on.png'
                                        : 'assets/img/sync_level_off.png',
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                              ),
                            if (selectedPair.hasSuperAwakening) ...[
                              for (int i = 6; i <= 10; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_moveLevel == i) {
                                          _moveLevel = i - 1;
                                        } else {
                                          _moveLevel = i;
                                        }
                                      });
                                    },
                                    child: Opacity(
                                      opacity: _moveLevel >= i ? 1.0 : 0.3,
                                      child: Image.asset(
                                        'assets/img/transcendance.png',
                                        width: 32,
                                        height: 32,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _activeCells.isNotEmpty
                                  ? () => setState(() {
                                      _activeCells.clear();
                                      if (_hardCap) {
                                        _activateFreeCenterCells(
                                          selectedPair.cells,
                                        );
                                      }
                                    })
                                  : null,
                              icon: const Icon(Icons.restart_alt),
                              tooltip: 'Reset Grid',
                            ),
                            if (!_expandedRight) ...[
                              const SizedBox(width: 8),
                              const Text('Hard Cap'),
                              Switch(
                                value: _hardCap,
                                onChanged: (value) {
                                  setState(() {
                                    _hardCap = value;
                                    if (value) {
                                      _activateFreeCenterCells(
                                        selectedPair.cells,
                                      );
                                      _pruneDisconnected(selectedPair.cells);
                                    }
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                        clipBehavior: Clip.antiAlias,
                        child: HexGridView(
                          cells: selectedPair.cells,
                          pairs: data.pairs,
                          activeCells: _activeCells,
                          syncMoveName: selectedPair.syncMoveName,
                          onToggleCell: (cellNumber) {
                            setState(() {
                              if (_activeCells.contains(cellNumber)) {
                                _activeCells.remove(cellNumber);
                                if (_hardCap) {
                                  _pruneDisconnected(selectedPair.cells);
                                }
                              } else {
                                final cell = selectedPair.cells.firstWhere(
                                  (c) => c.cellNumber == cellNumber,
                                );
                                if (cell.moveLevel > _moveLevel.clamp(1, 5)) {
                                  return;
                                }
                                if (_hardCap &&
                                    !_isAdjacentToActiveOrCenter(
                                      cell,
                                      selectedPair.cells,
                                    )) {
                                  return;
                                }
                                _activeCells.add(cellNumber);
                              }
                            });
                          },
                          onSelectPair: (index) {
                            setState(() {
                              _selectedPairIndex = index;
                              _activeCells.clear();
                              if (_hardCap) {
                                _activateFreeCenterCells(
                                  data.pairs[index].cells,
                                );
                              }
                            });
                          },
                          moveLevel: _moveLevel.clamp(1, 5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: _expandedRight ? 6 : 3,
                child: RightPanel(
                  pair: selectedPair,
                  activeCells: _activeCells,
                  selectedTab: _rightTab,
                  onTabChanged: (tab) => setState(() => _rightTab = tab),
                  moveLevel: _moveLevel.clamp(1, 5),
                  expanded: _expandedRight,
                  onToggleExpand: () =>
                      setState(() => _expandedRight = !_expandedRight),
                  superAwakeningLevel: selectedPair.hasSuperAwakening
                      ? (_moveLevel - 5).clamp(0, 5)
                      : 0,
                  luckySkills: data.luckySkills,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RightPanel extends StatelessWidget {
  const RightPanel({
    super.key,
    required this.pair,
    required this.activeCells,
    required this.selectedTab,
    required this.onTabChanged,
    required this.moveLevel,
    required this.expanded,
    required this.onToggleExpand,
    required this.superAwakeningLevel,
    required this.luckySkills,
  });

  final SyncPairData pair;
  final Set<int> activeCells;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final int moveLevel;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final int superAwakeningLevel;
  final List<LuckySkillDef> luckySkills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onToggleExpand,
                icon: Icon(
                  expanded ? Icons.chevron_right : Icons.chevron_left,
                  size: 20,
                ),
                tooltip: expanded ? 'Collapse' : 'Expand',
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pair.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pair.releaseDate != null)
                      Text(
                        'Available: ${pair.releaseDate!.day}/${pair.releaseDate!.month}/${pair.releaseDate!.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: selectedTab == 0 ? null : () => onTabChanged(0),
                  child: const Text('Overview'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: selectedTab == 1 ? null : () => onTabChanged(1),
                  child: const Text('Calculadora'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: selectedTab == 0
                ? SyncPairOverview(
                    pair: pair,
                    moveLevel: moveLevel,
                    activeCells: activeCells,
                    superAwakeningLevel: superAwakeningLevel,
                  )
                : DamageCalculatorPanel(
                    key: ValueKey(pair.number),
                    pair: pair,
                    activeCells: activeCells,
                    moveLevel: moveLevel,
                    expanded: expanded,
                    superAwakeningLevel: superAwakeningLevel,
                    luckySkills: luckySkills,
                  ),
          ),
        ],
      ),
    );
  }
}
