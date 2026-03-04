// lib/services/combat_service.dart

import 'package:crownfall/models/board.dart';
import 'package:crownfall/models/piece.dart';

class CombatService {
  /// Gestisce lo scontro tra attaccante e difensore.
  /// Restituisce il risultato del combattimento.
  static CombatResult resolveCombat({
    required Piece attacker,
    required Piece defender,
    required Position attackerPos,
    required Position defenderPos,
    required Board board,
  }) {
    // Entrambi si colpiscono simultaneamente
    final attackerNewHp = defender.stats.currentHp - attacker.stats.attack;
    final defenderNewHp = attacker.stats.currentHp - defender.stats.attack;

    final attackerDied = defenderNewHp <= 0;
    final defenderDied = attackerNewHp <= 0;

    Piece? survivingAttacker;
    Piece? survivingDefender;
    int coinsEarned = 0;
    Position? attackerNewPos;
    bool attackerMoved = false;

    if (!attackerDied) {
      survivingAttacker = attacker.copyWith(
        stats: attacker.stats.copyWith(currentHp: defenderNewHp.clamp(0, attacker.stats.maxHp)),
      );
    }

    if (!defenderDied) {
      survivingDefender = defender.copyWith(
        stats: defender.stats.copyWith(currentHp: attackerNewHp.clamp(0, defender.stats.maxHp)),
      );
    } else {
      coinsEarned += defender.stats.value;
    }

    if (defenderDied && !attackerDied) {
      // Attaccante avanza
      attackerNewPos = defenderPos;
      attackerMoved = true;
    } else if (!attackerDied && !defenderDied) {
      // Entrambi sopravvivono: attaccante torna indietro
      final path = _getPathPositions(attackerPos, defenderPos);
      // cerca la casella libera più vicina lungo il percorso
      Position? fallback;
      for (int i = path.length - 2; i >= 0; i--) {
        if (board.getPiece(path[i]) == null) {
          fallback = path[i];
          break;
        }
      }
      attackerNewPos = fallback ?? attackerPos;
      attackerMoved = false;
    }
    // Se l'attaccante muore, rimane solo il difensore (o nessuno se doppia morte)

    return CombatResult(
      survivingAttacker: survivingAttacker,
      survivingDefender: survivingDefender,
      coinsEarned: coinsEarned,
      attackerNewPosition: attackerNewPos,
      attackerMoved: attackerMoved,
    );
  }

  static List<Position> _getPathPositions(Position from, Position to) {
    final positions = <Position>[];
    final dr = (to.row - from.row).sign;
    final dc = (to.col - from.col).sign;
    var pos = Position(from.row + dr, from.col + dc);
    while (pos.row != to.row || pos.col != to.col) {
      positions.add(pos);
      pos = Position(pos.row + dr, pos.col + dc);
    }
    positions.add(to);
    return positions;
  }
}
