// lib/screens/online_game_screen.dart
//
// Schermata di gioco per il multiplayer online.
// Simile a GameScreen ma usa OnlineGameProvider
// e mostra indicatori di connessione e attesa avversario.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/providers/game_provider.dart';
import 'package:crownfall/providers/online_game_provider.dart';
import 'package:crownfall/widgets/online_game_board_widget.dart';

class OnlineGameScreen extends StatelessWidget {
  const OnlineGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<OnlineGameProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _OnlineOpponentBar(game: game),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Board con orientamento in base al ruolo
                        OnlineGameBoardWidget(isFlipped: game.myRole == PlayerSide.player2),
                        const SizedBox(height: 8),
                        if (game.lastCombatLog != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              game.lastCombatLog!,
                              style: const TextStyle(color: Colors.amber, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _OnlinePlayerBar(game: game),
              ],
            ),

            // Overlay: attesa board
            if (!game.boardReady)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.amber),
                      SizedBox(height: 20),
                      Text(
                        'In attesa dell\'avversario...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'La partita inizierà quando entrambi i giocatori sono pronti.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Overlay: disconnessione
            if (game.opponentDisconnected)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.red, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Connessione persa',
                        style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Controlla la tua connessione di rete.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Esci', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra avversario (in alto) ───────────────────

class _OnlineOpponentBar extends StatelessWidget {
  final OnlineGameProvider game;
  const _OnlineOpponentBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final isOpponentTurn = game.phase == GamePhase.waitingForOpponent;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: game.myRole == PlayerSide.player1 ? Colors.red : Colors.cyan,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.opponentProfile.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '${game.opponentProfile.wins}V - ${game.opponentProfile.losses}S',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          if (isOpponentTurn && game.boardReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                  ),
                  SizedBox(width: 6),
                  Text('Sta giocando...', style: TextStyle(color: Colors.orange, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Barra giocatore (in basso) ───────────────────

class _OnlinePlayerBar extends StatelessWidget {
  final OnlineGameProvider game;
  const _OnlinePlayerBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = game.isMyTurn;

    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF16213E),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: game.myRole == PlayerSide.player1 ? Colors.cyan : Colors.red,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.myProfile.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('${game.myProfile.coins}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (isMyTurn) ...[
                if (game.selectedPosition != null) ...[
                  _AbilityButton(game: game),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: game.endTurn,
                  icon: const Icon(Icons.skip_next, size: 16),
                  label: const Text('Fine turno'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3460),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
              if (game.phase == GamePhase.gameOver)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text('Fine partita', style: TextStyle(color: Colors.black)),
                ),
            ],
          ),
          if (isMyTurn)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.4)),
                ),
                child: Text(
                  game.turnAction == TurnAction.moved
                      ? 'Hai mosso. Puoi usare un\'abilità o finire il turno.'
                      : game.turnAction == TurnAction.usedAbility
                          ? 'Abilità usata. Puoi muovere o finire il turno.'
                          : '🎮 Il tuo turno — seleziona un pezzo',
                  style: const TextStyle(color: Colors.cyan, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (game.phase == GamePhase.gameOver)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _gameOverMessage(game),
                style: TextStyle(
                  color: _isWinner(game) ? Colors.amber : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  bool _isWinner(OnlineGameProvider game) {
    // Se il re avversario non c'è, ho vinto
    final oppSide = game.myRole == PlayerSide.player1 ? PlayerSide.player2 : PlayerSide.player1;
    return game.board.findKing(oppSide) == null;
  }

  String _gameOverMessage(OnlineGameProvider game) {
    return _isWinner(game) ? '🏆 Hai vinto! +200 monete' : '💀 Hai perso. +10 monete';
  }
}

class _AbilityButton extends StatelessWidget {
  final OnlineGameProvider game;
  const _AbilityButton({required this.game});

  @override
  Widget build(BuildContext context) {
    final pos = game.selectedPosition!;
    final piece = game.board.getPiece(pos);
    if (piece?.specialAbility == null) return const SizedBox.shrink();

    final ability = piece!.specialAbility!;
    final canUse = ability.isReady && game.canUseAbility;

    return Tooltip(
      message: '${ability.name}: ${ability.description}',
      child: ElevatedButton.icon(
        onPressed: canUse ? () => game.useAbility(pos) : null,
        icon: const Icon(Icons.flash_on, size: 14),
        label: Text(ability.name, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: canUse ? Colors.purple : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    );
  }
}
