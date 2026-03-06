// lib/services/serialization_service.dart
//
// Serializza e deserializza Board, Piece e PlayerProfile in/da JSON
// per la sincronizzazione con Firestore.

import 'package:crownfall/models/board.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/piece_definitions.dart';
import 'package:crownfall/models/player_profile.dart';

class SerializationService {
  // ─────────────────────────────────────────────
  // PIECE
  // ─────────────────────────────────────────────

  static Map<String, dynamic> pieceToJson(Piece piece) {
    return {
      'id': piece.id,
      'type': piece.type.name,
      'baseType': piece.baseType.name,
      'side': piece.side.name,
      'hasMoved': piece.hasMoved,
      'equippedSkin': piece.equippedSkin,
      'stats': {
        'maxHp': piece.stats.maxHp,
        'currentHp': piece.stats.currentHp,
        'attack': piece.stats.attack,
        'value': piece.stats.value,
        'hpLevel': piece.stats.hpLevel,
        'attackLevel': piece.stats.attackLevel,
        'valueLevel': piece.stats.valueLevel,
      },
      'abilityCooldown': piece.specialAbility?.currentCooldown ?? 0,
    };
  }

  static Piece pieceFromJson(Map<String, dynamic> json) {
    final type = PieceType.values.firstWhere((e) => e.name == json['type']);
    final baseType = PieceBaseType.values.firstWhere((e) => e.name == json['baseType']);
    final side = PlayerSide.values.firstWhere((e) => e.name == json['side']);
    final statsJson = json['stats'] as Map<String, dynamic>;

    final stats = PieceStats(
      maxHp: statsJson['maxHp'] as int,
      currentHp: statsJson['currentHp'] as int,
      attack: statsJson['attack'] as int,
      value: statsJson['value'] as int,
      hpLevel: statsJson['hpLevel'] as int,
      attackLevel: statsJson['attackLevel'] as int,
      valueLevel: statsJson['valueLevel'] as int,
    );

    // Ricostruisce l'abilità dalla definizione del pezzo
    final def = pieceDefinitions[type];
    SpecialAbility? ability = def?.abilityFactory?.call();
    if (ability != null) {
      ability.currentCooldown = json['abilityCooldown'] as int? ?? 0;
    }

    return Piece(
      id: json['id'] as String,
      type: type,
      baseType: baseType,
      side: side,
      stats: stats,
      specialAbility: ability,
      equippedSkin: json['equippedSkin'] as String?,
      hasMoved: json['hasMoved'] as bool? ?? false,
    );
  }

  // ─────────────────────────────────────────────
  // BOARD
  // ─────────────────────────────────────────────

  /// Serializza la board come lista di 64 elementi (riga per riga, null se vuota).
  static List<dynamic> boardToJson(Board board) {
    final cells = <dynamic>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board.getPiece(Position(r, c));
        cells.add(piece != null ? pieceToJson(piece) : null);
      }
    }
    return cells;
  }

  static Board boardFromJson(List<dynamic> cells) {
    final board = Board();
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final raw = cells[r * 8 + c];
        if (raw != null) {
          board.setPiece(Position(r, c), pieceFromJson(Map<String, dynamic>.from(raw as Map)));
        }
      }
    }
    return board;
  }

  // ─────────────────────────────────────────────
  // PLAYER PROFILE (solo dati necessari per online)
  // ─────────────────────────────────────────────

  static Map<String, dynamic> profileToJson(PlayerProfile profile) {
    return {
      'name': profile.name,
      'wins': profile.wins,
      'losses': profile.losses,
      'armyConfig': profile.armyConfig.toJson(),
      'upgradeLevels': profile.upgradeLevels.map(
        (k, v) => MapEntry(k.name, v.toJson()),
      ),
    };
  }

  static PlayerProfile profileFromJson(Map<String, dynamic> json) {
    final upgradeJson = json['upgradeLevels'] as Map<String, dynamic>? ?? {};
    final upgradeLevels = upgradeJson.map(
      (k, v) => MapEntry(
        PieceType.values.firstWhere((e) => e.name == k),
        UpgradeLevel.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );

    return PlayerProfile(
      name: json['name'] as String,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      armyConfig: ArmyConfig.fromJson(Map<String, dynamic>.from(json['armyConfig'] as Map)),
      upgradeLevels: upgradeLevels,
    );
  }
}
