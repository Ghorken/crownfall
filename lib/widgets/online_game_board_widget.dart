// lib/widgets/online_game_board_widget.dart
//
// Versione della scacchiera per il multiplayer online.
// Usa OnlineGameProvider e supporta il flip della board
// (player2 vede i propri pezzi in basso).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/board.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/providers/online_game_provider.dart';
import 'package:crownfall/widgets/piece_widget.dart';

class OnlineGameBoardWidget extends StatelessWidget {
  final bool isFlipped;

  const OnlineGameBoardWidget({super.key, this.isFlipped = false});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF5D4037), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            // Se flippato, invertiamo l'indice per mostrare
            // le righe dal basso verso l'alto (player2 in basso)
            final displayIndex = isFlipped ? 63 - index : index;
            final row = displayIndex ~/ 8;
            final col = displayIndex % 8;
            final pos = Position(row, col);
            return _OnlineBoardCell(position: pos, isFlipped: isFlipped);
          },
        ),
      ),
    );
  }
}

class _OnlineBoardCell extends StatelessWidget {
  final Position position;
  final bool isFlipped;

  const _OnlineBoardCell({required this.position, required this.isFlipped});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<OnlineGameProvider>();
    if (!game.boardReady) {
      // Board non ancora pronta: mostra solo la scacchiera vuota
      final isLight = (position.row + position.col) % 2 == 0;
      return Container(color: isLight ? const Color(0xFFECCB82) : const Color(0xFF8B4513));
    }

    final piece = game.board.getPiece(position);
    final isLight = (position.row + position.col) % 2 == 0;
    final isSelected = game.selectedPosition == position;
    final isValidMove = game.validMoves.contains(position);
    final isMyPiece = piece?.side == game.myRole;

    Color cellColor;
    if (isSelected) {
      cellColor = const Color(0xFFF9A825).withValues(alpha: 0.8);
    } else if (isValidMove) {
      cellColor = piece != null
          ? Colors.red.withValues(alpha: 0.5)
          : const Color(0xFF00E5FF).withValues(alpha: 0.4);
    } else {
      cellColor = isLight ? const Color(0xFFECCB82) : const Color(0xFF8B4513);
    }

    // Coordinate visibili: adattate al flip
    final displayRow = isFlipped ? 7 - position.row : position.row;
    final displayCol = isFlipped ? 7 - position.col : position.col;

    return GestureDetector(
      onTap: () => game.selectPosition(position),
      child: Container(
        color: cellColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Indicatore mossa valida
            if (isValidMove && piece == null)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyan.withValues(alpha: 0.7),
                ),
              ),

            // Pezzo
            if (piece != null)
              Padding(
                padding: const EdgeInsets.all(2),
                child: PieceWidget(
                  piece: piece,
                  size: double.infinity,
                  showStats: isMyPiece,
                  isSelected: isSelected,
                ),
              ),

            // Etichette coordinate
            if (displayCol == 0)
              Positioned(
                top: 1,
                left: 2,
                child: Text(
                  '${8 - displayRow}',
                  style: TextStyle(
                    fontSize: 8,
                    color: isLight ? const Color(0xFF8B4513) : const Color(0xFFECCB82),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (displayRow == 7)
              Positioned(
                bottom: 1,
                right: 2,
                child: Text(
                  String.fromCharCode(65 + displayCol),
                  style: TextStyle(
                    fontSize: 8,
                    color: isLight ? const Color(0xFF8B4513) : const Color(0xFFECCB82),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
