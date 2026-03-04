// lib/providers/shop_provider.dart

import 'package:flutter/foundation.dart';
import 'package:crownfall/models/player_profile.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/piece_definitions.dart';

class ShopSkinItem {
  final String skinId;
  final String name;
  final String description;
  final int cost;
  final PieceType? targetPiece; // null = skin intera armata

  const ShopSkinItem({
    required this.skinId,
    required this.name,
    required this.description,
    required this.cost,
    this.targetPiece,
  });
}

// Catalogo skin disponibili - espandibile facilmente
const List<ShopSkinItem> availableSkins = [
  ShopSkinItem(
    skinId: 'army_fire',
    name: 'Armata del Fuoco',
    description: 'Tinge tutti i tuoi pezzi di rosso ardente',
    cost: 1000,
  ),
  ShopSkinItem(
    skinId: 'army_ice',
    name: 'Armata del Ghiaccio',
    description: 'Pezzi cristallizzati in blu glaciale',
    cost: 1000,
  ),
  ShopSkinItem(
    skinId: 'pawn_shadow',
    name: 'Pedone Ombra',
    description: 'Skin oscura per i tuoi pedoni',
    cost: 200,
    targetPiece: PieceType.pawn,
  ),
  ShopSkinItem(
    skinId: 'queen_golden',
    name: 'Regina Dorata',
    description: 'La tua regina splende d\'oro',
    cost: 500,
    targetPiece: PieceType.queen,
  ),
];

class ShopProvider extends ChangeNotifier {
  final PlayerProfile profile;

  ShopProvider({required this.profile});

  // ===== SBLOCCO PEZZI =====
  bool canUnlock(PieceType type) {
    final def = pieceDefinitions[type];
    if (def == null || !def.isUnlockable) return false;
    if (profile.hasPiece(type)) return false;
    return profile.coins >= def.unlockCost;
  }

  bool unlockPiece(PieceType type) {
    final def = pieceDefinitions[type];
    if (def == null || !canUnlock(type)) return false;
    profile.coins -= def.unlockCost;
    profile.unlockedPieces.add(type);
    notifyListeners();
    return true;
  }

  // ===== UPGRADES =====
  int getUpgradeCost(PieceType type, String stat) {
    final def = pieceDefinitions[type];
    if (def == null) return 0;
    final levels = profile.getUpgradeLevel(type);
    final currentLevel = switch (stat) {
      'hp' => levels.hpLevel,
      'attack' => levels.attackLevel,
      'value' => levels.valueLevel,
      _ => 1,
    };
    return def.getUpgradeCost(currentLevel);
  }

  bool upgradeStat(PieceType type, String stat) {
    final cost = getUpgradeCost(type, stat);
    if (profile.coins < cost) return false;

    profile.coins -= cost;
    final levels = profile.upgradeLevels[type] ?? UpgradeLevel(pieceType: type);

    switch (stat) {
      case 'hp':
        levels.hpLevel++;
      case 'attack':
        levels.attackLevel++;
      case 'value':
        levels.valueLevel++;
    }
    profile.upgradeLevels[type] = levels;
    notifyListeners();
    return true;
  }

  // ===== INIZIATIVA =====
  int get initiativeUpgradeCost => 300 * profile.initiative;

  bool upgradeInitiative() {
    if (profile.coins < initiativeUpgradeCost) return false;
    profile.coins -= initiativeUpgradeCost;
    profile.initiative++;
    notifyListeners();
    return true;
  }

  // ===== SKIN =====
  bool hasSkin(String skinId) => profile.ownedSkins.any((s) => s.skinId == skinId);

  bool buySkin(ShopSkinItem item) {
    if (hasSkin(item.skinId) || profile.coins < item.cost) return false;
    profile.coins -= item.cost;
    profile.ownedSkins.add(SkinOwnership(
      skinId: item.skinId,
      name: item.name,
      targetPiece: item.targetPiece,
    ));
    notifyListeners();
    return true;
  }

  void equipSkin(String skinId) {
    for (final skin in profile.ownedSkins) {
      skin.isEquipped = skin.skinId == skinId;
    }
    notifyListeners();
  }
}
