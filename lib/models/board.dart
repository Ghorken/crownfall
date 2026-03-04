// lib/models/board.dart

import 'package:crownfall/models/piece.dart';

class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 8;

  @override
  bool operator ==(Object other) => other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => row * 8 + col;

  @override
  String toString() => '($row,$col)';

  Position operator +(Position other) => Position(row + other.row, col + other.col);
}

class CombatResult {
  final Piece? survivingAttacker; // null = morto
  final Piece? survivingDefender; // null = morto
  final int coinsEarned;
  final Position? attackerNewPosition; // dove si posiziona l'attaccante se sopravvive
  final bool attackerMoved; // true se l'attaccante occupa la cella del difensore

  CombatResult({
    required this.survivingAttacker,
    required this.survivingDefender,
    required this.coinsEarned,
    this.attackerNewPosition,
    this.attackerMoved = false,
  });
}

class Board {
  // board[row][col] = Piece?
  final List<List<Piece?>> cells;

  Board() : cells = List.generate(8, (_) => List.filled(8, null));

  Board.from(Board other) : cells = List.generate(8, (r) => List.generate(8, (c) => other.cells[r][c]));

  Piece? getPiece(Position pos) => cells[pos.row][pos.col];
  void setPiece(Position pos, Piece? piece) => cells[pos.row][pos.col] = piece;

  void movePiece(Position from, Position to) {
    final piece = getPiece(from);
    setPiece(to, piece);
    setPiece(from, null);
  }

  List<Position> getAllPositionsOf(PlayerSide side) {
    final positions = <Position>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = cells[r][c];
        if (p != null && p.side == side) {
          positions.add(Position(r, c));
        }
      }
    }
    return positions;
  }

  Position? findKing(PlayerSide side) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = cells[r][c];
        if (p != null && p.side == side && p.baseType == PieceBaseType.king) {
          return Position(r, c);
        }
      }
    }
    return null;
  }
}
