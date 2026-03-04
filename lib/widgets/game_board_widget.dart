// lib/widgets/game_board_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/board.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/providers/game_provider.dart';
import 'package:crownfall/widgets/piece_widget.dart';

class GameBoardWidget extends StatelessWidget {
  const GameBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

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
            )
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final row = index ~/ 8;
            final col = index % 8;
            final pos = Position(row, col);
            return _BoardCell(position: pos);
          },
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  final Position position;

  const _BoardCell({required this.position});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final piece = game.board.getPiece(position);
    final isLight = (position.row + position.col) % 2 == 0;
    final isSelected = game.selectedPosition == position;
    final isValidMove = game.validMoves.contains(position);
    final isMyPiece = piece?.side == PlayerSide.player1;

    Color cellColor;
    if (isSelected) {
      cellColor = const Color(0xFFF9A825).withValues(alpha: 0.8);
    } else if (isValidMove) {
      cellColor = piece != null
          ? Colors.red.withValues(alpha: 0.5) // casella con nemico
          : const Color(0xFF00E5FF).withValues(alpha: 0.4);
    } else {
      cellColor = isLight ? const Color(0xFFECCB82) : const Color(0xFF8B4513);
    }

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

            // Label coordinata (opzionale, angolo in alto a sinistra per col 0 e row 7)
            if (position.col == 0)
              Positioned(
                top: 1,
                left: 2,
                child: Text(
                  '${8 - position.row}',
                  style: TextStyle(
                    fontSize: 8,
                    color: isLight ? const Color(0xFF8B4513) : const Color(0xFFECCB82),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (position.row == 7)
              Positioned(
                bottom: 1,
                right: 2,
                child: Text(
                  String.fromCharCode(65 + position.col),
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
