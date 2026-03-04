// lib/services/movement_service.dart
// Calcola le mosse valide per ogni tipo di pezzo

import 'package:crownfall/models/board.dart';
import 'package:crownfall/models/piece.dart';

class MovementService {
  static List<Position> getValidMoves(Board board, Position from) {
    final piece = board.getPiece(from);
    if (piece == null) return [];

    return switch (piece.baseType) {
      PieceBaseType.pawn => _pawnMoves(board, from, piece),
      PieceBaseType.rook => _slidingMoves(board, from, piece, _rookDirections),
      PieceBaseType.knight => _knightMoves(board, from, piece),
      PieceBaseType.bishop => _slidingMoves(board, from, piece, _bishopDirections),
      PieceBaseType.queen => _slidingMoves(board, from, piece, _queenDirections),
      PieceBaseType.king => _kingMoves(board, from, piece),
    };
  }

  static const _rookDirections = [Position(1, 0), Position(-1, 0), Position(0, 1), Position(0, -1)];
  static const _bishopDirections = [Position(1, 1), Position(1, -1), Position(-1, 1), Position(-1, -1)];
  static const _queenDirections = [Position(1, 0), Position(-1, 0), Position(0, 1), Position(0, -1), Position(1, 1), Position(1, -1), Position(-1, 1), Position(-1, -1)];

  static List<Position> _pawnMoves(Board board, Position from, Piece piece) {
    final moves = <Position>[];
    final dir = piece.side == PlayerSide.player1 ? -1 : 1;
    final forward = Position(from.row + dir, from.col);

    if (forward.isValid && board.getPiece(forward) == null) {
      moves.add(forward);
      // doppio passo iniziale
      if (!piece.hasMoved) {
        final doubleForward = Position(from.row + dir * 2, from.col);
        if (doubleForward.isValid && board.getPiece(doubleForward) == null) {
          moves.add(doubleForward);
        }
      }
    }

    // Catture diagonali
    for (final dc in [-1, 1]) {
      final capturePos = Position(from.row + dir, from.col + dc);
      if (capturePos.isValid) {
        final target = board.getPiece(capturePos);
        if (target != null && target.side != piece.side) {
          moves.add(capturePos);
        }
      }
    }

    return moves;
  }

  static List<Position> _slidingMoves(Board board, Position from, Piece piece, List<Position> directions) {
    final moves = <Position>[];
    for (final dir in directions) {
      var pos = from + dir;
      while (pos.isValid) {
        final target = board.getPiece(pos);
        if (target == null) {
          moves.add(pos);
        } else {
          if (target.side != piece.side) moves.add(pos); // può attaccare
          break;
        }
        pos = pos + dir;
      }
    }
    return moves;
  }

  static List<Position> _knightMoves(Board board, Position from, Piece piece) {
    final offsets = [
      Position(2, 1),
      Position(2, -1),
      Position(-2, 1),
      Position(-2, -1),
      Position(1, 2),
      Position(1, -2),
      Position(-1, 2),
      Position(-1, -2),
    ];
    final moves = <Position>[];
    for (final offset in offsets) {
      final pos = from + offset;
      if (!pos.isValid) continue;
      final target = board.getPiece(pos);
      if (target == null || target.side != piece.side) moves.add(pos);
    }
    return moves;
  }

  static List<Position> _kingMoves(Board board, Position from, Piece piece) {
    final moves = <Position>[];
    for (final dir in _queenDirections) {
      final pos = from + dir;
      if (!pos.isValid) continue;
      final target = board.getPiece(pos);
      if (target == null || target.side != piece.side) moves.add(pos);
    }
    // TODO: aggiungere castling
    return moves;
  }

  /// Ritorna la casella libera più vicina lungo il percorso
  /// usata quando l'attaccante non riesce a conquistare la casella
  static Position? getNearestFreePositionOnPath(Board board, Position from, Position to) {
    // Calcola il percorso rettilineo (per torri/regine) o la posizione precedente
    final positions = getPathPositions(from, to);
    // Cerca all'indietro l'ultima posizione libera prima della destinazione
    for (int i = positions.length - 2; i >= 0; i--) {
      if (board.getPiece(positions[i]) == null) {
        return positions[i];
      }
    }
    return null;
  }

  static List<Position> getPathPositions(Position from, Position to) {
    final positions = <Position>[];
    final dr = (to.row - from.row).sign;
    final dc = (to.col - from.col).sign;
    var pos = Position(from.row + dr, from.col + dc);
    while (pos != to) {
      positions.add(pos);
      pos = Position(pos.row + dr, pos.col + dc);
    }
    positions.add(to);
    return positions;
  }
}
