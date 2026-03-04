// lib/models/player_profile.dart

import 'package:flutter/foundation.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/piece_definitions.dart';

class UpgradeLevel {
  final PieceType pieceType;
  int hpLevel;
  int attackLevel;
  int valueLevel;

  UpgradeLevel({
    required this.pieceType,
    this.hpLevel = 1,
    this.attackLevel = 1,
    this.valueLevel = 1,
  });

  Map<String, dynamic> toJson() => {
        'pieceType': pieceType.name,
        'hpLevel': hpLevel,
        'attackLevel': attackLevel,
        'valueLevel': valueLevel,
      };

  factory UpgradeLevel.fromJson(Map<String, dynamic> json) => UpgradeLevel(
        pieceType: PieceType.values.firstWhere((e) => e.name == json['pieceType']),
        hpLevel: json['hpLevel'],
        attackLevel: json['attackLevel'],
        valueLevel: json['valueLevel'],
      );
}

class SkinOwnership {
  final String skinId;
  final String name;
  final PieceType? targetPiece; // null = skin per tutti i pezzi (army skin)
  bool isEquipped;

  SkinOwnership({
    required this.skinId,
    required this.name,
    this.targetPiece,
    this.isEquipped = false,
  });
}

// Configurazione dell'esercito del giocatore
class ArmyConfig {
  // Mappa pieceType -> count (quanti ne metti nell'esercito)
  final Map<PieceType, int> composition;

  ArmyConfig({Map<PieceType, int>? composition}) : composition = composition ?? _defaultComposition();

  static Map<PieceType, int> _defaultComposition() => {
        PieceType.pawn: 8,
        PieceType.rook: 2,
        PieceType.knight: 2,
        PieceType.bishop: 2,
        PieceType.queen: 1,
        PieceType.king: 1,
      };

  bool isValid() {
    // Verifica limiti per tipo base
    final countByBase = <PieceBaseType, int>{};
    for (final entry in composition.entries) {
      if (entry.value <= 0) continue;
      final def = pieceDefinitions[entry.key];
      if (def == null) continue;
      countByBase[def.baseType] = (countByBase[def.baseType] ?? 0) + entry.value;
    }
    for (final entry in countByBase.entries) {
      final max = pieceMaxCount[entry.key] ?? 0;
      if (entry.value > max) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'composition': composition.map((k, v) => MapEntry(k.name, v)),
      };

  factory ArmyConfig.fromJson(Map<String, dynamic> json) {
    final comp = (json['composition'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(
        PieceType.values.firstWhere((e) => e.name == k),
        v as int,
      ),
    );
    return ArmyConfig(composition: comp);
  }
}

class PlayerProfile extends ChangeNotifier {
  String name;
  int coins;
  int initiative; // livello di iniziativa
  Set<PieceType> unlockedPieces;
  Map<PieceType, UpgradeLevel> upgradeLevels;
  List<SkinOwnership> ownedSkins;
  ArmyConfig armyConfig;
  int wins;
  int losses;

  PlayerProfile({
    required this.name,
    this.coins = 500, // monete iniziali
    this.initiative = 1,
    Set<PieceType>? unlockedPieces,
    Map<PieceType, UpgradeLevel>? upgradeLevels,
    List<SkinOwnership>? ownedSkins,
    ArmyConfig? armyConfig,
    this.wins = 0,
    this.losses = 0,
  })  : unlockedPieces = unlockedPieces ??
            {
              PieceType.pawn,
              PieceType.rook,
              PieceType.knight,
              PieceType.bishop,
              PieceType.queen,
              PieceType.king,
            },
        upgradeLevels = upgradeLevels ?? {},
        ownedSkins = ownedSkins ?? [],
        armyConfig = armyConfig ?? ArmyConfig();

  bool hasPiece(PieceType type) => unlockedPieces.contains(type);

  UpgradeLevel getUpgradeLevel(PieceType type) => upgradeLevels[type] ?? UpgradeLevel(pieceType: type);

  PieceStats getStatsForPiece(PieceType type) {
    final def = pieceDefinitions[type]!;
    final levels = getUpgradeLevel(type);
    return PieceStats(
      maxHp: def.getStatAtLevel(def.baseHp, def.hpScaleFactor, levels.hpLevel),
      currentHp: def.getStatAtLevel(def.baseHp, def.hpScaleFactor, levels.hpLevel),
      attack: def.getStatAtLevel(def.baseAttack, def.attackScaleFactor, levels.attackLevel),
      value: def.getStatAtLevel(def.baseValue, def.valueScaleFactor, levels.valueLevel),
    );
  }
}
