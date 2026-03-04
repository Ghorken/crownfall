// lib/screens/army_builder_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/piece_definitions.dart';
import 'package:crownfall/models/player_profile.dart';
import 'package:crownfall/widgets/piece_widget.dart';

class ArmyBuilderScreen extends StatefulWidget {
  const ArmyBuilderScreen({super.key});

  @override
  State<ArmyBuilderScreen> createState() => _ArmyBuilderScreenState();
}

class _ArmyBuilderScreenState extends State<ArmyBuilderScreen> {
  late Map<PieceType, int> _draft;
  late PlayerProfile _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profile = context.read<PlayerProfile>();
    _draft = Map.from(_profile.armyConfig.composition);
  }

  int _countForBase(PieceBaseType base) {
    int total = 0;
    _draft.forEach((type, count) {
      final def = pieceDefinitions[type];
      if (def != null && def.baseType == base) total += count;
    });
    return total;
  }

  bool _canAdd(PieceType type) {
    final def = pieceDefinitions[type]!;
    final max = pieceMaxCount[def.baseType] ?? 0;
    return _countForBase(def.baseType) < max;
  }

  void _add(PieceType type) {
    if (!_canAdd(type)) return;
    setState(() {
      _draft[type] = (_draft[type] ?? 0) + 1;
    });
  }

  void _remove(PieceType type) {
    setState(() {
      final cur = _draft[type] ?? 0;
      if (cur <= 0) return;
      if (cur == 1) {
        _draft.remove(type);
      } else {
        _draft[type] = cur - 1;
      }
    });
  }

  bool get _isValid => ArmyConfig(composition: _draft).isValid();

  void _save() {
    if (!_isValid) return;
    _profile.armyConfig = ArmyConfig(composition: _draft);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esercito salvato!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <PieceBaseType, List<PieceDefinition>>{};
    for (final def in pieceDefinitions.values) {
      if (_profile.hasPiece(def.type)) {
        groups.putIfAbsent(def.baseType, () => []).add(def);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Costruisci Esercito', style: TextStyle(color: Colors.amber)),
        actions: [
          TextButton.icon(
            onPressed: _isValid ? _save : null,
            icon: const Icon(Icons.save, color: Colors.amber),
            label: const Text('Salva', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F3460),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: PieceBaseType.values.map((base) {
                final current = _countForBase(base);
                final max = pieceMaxCount[base] ?? 0;
                return Column(
                  children: [
                    Text(
                      _baseLabel(base),
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    Text(
                      '$current/$max',
                      style: TextStyle(
                        color: current == max ? Colors.amber : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: PieceBaseType.values.map((base) {
                final pieces = groups[base] ?? [];
                if (pieces.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${_baseLabel(base)} (${_countForBase(base)}/${pieceMaxCount[base]})',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...pieces.map((def) => _PieceRow(
                          def: def,
                          count: _draft[def.type] ?? 0,
                          canAdd: _canAdd(def.type),
                          onAdd: () => _add(def.type),
                          onRemove: () => _remove(def.type),
                        )),
                    const Divider(color: Colors.white12),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _baseLabel(PieceBaseType base) => switch (base) {
        PieceBaseType.pawn => 'Pedoni',
        PieceBaseType.rook => 'Torri',
        PieceBaseType.knight => 'Cavalli',
        PieceBaseType.bishop => 'Alfieri',
        PieceBaseType.queen => 'Regine',
        PieceBaseType.king => 'Re',
      };
}

class _PieceRow extends StatelessWidget {
  final PieceDefinition def;
  final int count;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PieceRow({
    required this.def,
    required this.count,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: PieceWidget(
                piece: Piece(
                  id: 'builder_${def.type}',
                  type: def.type,
                  baseType: def.baseType,
                  side: PlayerSide.player1,
                  stats: def.createStats(),
                ),
                size: 40,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(def.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    '❤️${def.baseHp} ⚔️${def.baseAttack} 🪙${def.baseValue}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: count > 0 ? onRemove : null,
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canAdd ? onAdd : null,
                  icon: Icon(Icons.add_circle, color: canAdd ? Colors.green : Colors.grey),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
