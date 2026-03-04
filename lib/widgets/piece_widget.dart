// lib/widgets/piece_placeholder_painter.dart
// Disegna placeholder colorati per i pezzi finché non hai asset reali

import 'package:flutter/material.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/piece_definitions.dart';

class PiecePlaceholderPainter extends CustomPainter {
  final PieceType type;
  final PlayerSide side;
  final bool isHalfHp;

  PiecePlaceholderPainter({
    required this.type,
    required this.side,
    required this.isHalfHp,
  });

  // Colore base per tipo di pezzo
  static Color _pieceColor(PieceType type) => switch (type) {
        PieceType.pawn || PieceType.fighter || PieceType.miner || PieceType.rifleman => const Color(0xFF8BC34A),
        PieceType.rook || PieceType.catapult || PieceType.ironWall => const Color(0xFF607D8B),
        PieceType.knight || PieceType.paladin || PieceType.shadowRider => const Color(0xFF9C27B0),
        PieceType.bishop || PieceType.healer || PieceType.investigator || PieceType.invisibleMan => const Color(0xFF2196F3),
        PieceType.queen || PieceType.warlord || PieceType.heartQueen || PieceType.soulReaper => const Color(0xFFFF9800),
        PieceType.king || PieceType.commander => const Color(0xFFFFD700),
      };

  // Simbolo per tipo base
  static String _symbol(PieceBaseType base) => switch (base) {
        PieceBaseType.pawn => '♟',
        PieceBaseType.rook => '♜',
        PieceBaseType.knight => '♞',
        PieceBaseType.bishop => '♝',
        PieceBaseType.queen => '♛',
        PieceBaseType.king => '♚',
      };

  @override
  void paint(Canvas canvas, Size size) {
    final def = pieceDefinitions[type]!;
    var color = _pieceColor(type);

    // A metà vita il pezzo appare più scuro/graffiato
    if (isHalfHp) color = color.withValues(alpha: 0.6);

    // Bordo che identifica il lato del giocatore
    final borderColor = side == PlayerSide.player1
        ? const Color(0xFF00E5FF) // ciano per giocatore 1
        : const Color(0xFFFF5252); // rosso per giocatore 2

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Sfondo circolare
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color,
    );

    // Bordo colorato per identificare il lato
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Se a metà vita, disegna una crepa
    if (isHalfHp) {
      final crackPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(size.width * 0.4, size.height * 0.2);
      path.lineTo(size.width * 0.55, size.height * 0.5);
      path.lineTo(size.width * 0.35, size.height * 0.8);
      canvas.drawPath(path, crackPaint);
    }

    // Simbolo scacchi al centro
    final textPainter = TextPainter(
      text: TextSpan(
        text: _symbol(def.baseType),
        style: TextStyle(
          fontSize: size.width * 0.55,
          color: Colors.white.withValues(alpha: isHalfHp ? 0.6 : 0.95),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(PiecePlaceholderPainter old) => old.type != type || old.side != side || old.isHalfHp != isHalfHp;
}

/// Widget che mostra il pezzo: usa asset PNG se esistono, altrimenti il placeholder
class PieceWidget extends StatelessWidget {
  final Piece piece;
  final double size;
  final bool showStats; // mostra HP/ATK solo se è il tuo pezzo
  final bool isSelected;

  const PieceWidget({
    super.key,
    required this.piece,
    this.size = 48,
    this.showStats = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // ============================================================
          // GESTIONE ASSET:
          // Quando hai le immagini reali, sostituisci il CustomPaint
          // con Image.asset(piece.imagePath, fit: BoxFit.contain)
          //
          // Esempio:
          // Image.asset(
          //   piece.imagePath,  // es: 'assets/images/pieces/pawn_full.png'
          //   fit: BoxFit.contain,
          //   errorBuilder: (_, __, ___) => _buildPlaceholder(),
          // )
          // ============================================================
          _buildPlaceholder(),

          if (isSelected)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.yellowAccent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellowAccent.withValues(alpha: 0.5),
                    blurRadius: 8,
                  )
                ],
              ),
            ),

          // Barra HP piccola in basso
          if (showStats)
            Positioned(
              bottom: 0,
              left: 2,
              right: 2,
              child: _HpBar(
                current: piece.stats.currentHp,
                max: piece.stats.maxHp,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() => CustomPaint(
        painter: PiecePlaceholderPainter(
          type: piece.type,
          side: piece.side,
          isHalfHp: piece.stats.isHalfHp,
        ),
      );
}

class _HpBar extends StatelessWidget {
  final int current;
  final int max;

  const _HpBar({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final ratio = current / max;
    final color = ratio > 0.5
        ? Colors.green
        : ratio > 0.25
            ? Colors.orange
            : Colors.red;
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
