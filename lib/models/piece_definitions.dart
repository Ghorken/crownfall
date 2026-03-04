// lib/models/piece_definitions.dart
// Configurazione di tutti i pezzi del gioco

import 'package:crownfall/models/piece.dart';

class PieceDefinition {
  final PieceType type;
  final PieceBaseType baseType;
  final String displayName;
  final String description;
  final int baseHp;
  final int baseAttack;
  final int baseValue;
  final bool isUnlockable;
  final int unlockCost;
  // Fattori di scaling per upgrades (moltiplicatori per livello)
  final double hpScaleFactor;
  final double attackScaleFactor;
  final double valueScaleFactor;
  final int upgradeCostBase;
  final SpecialAbility? Function()? abilityFactory;

  const PieceDefinition({
    required this.type,
    required this.baseType,
    required this.displayName,
    required this.description,
    required this.baseHp,
    required this.baseAttack,
    required this.baseValue,
    required this.isUnlockable,
    this.unlockCost = 0,
    this.hpScaleFactor = 1.3,
    this.attackScaleFactor = 1.25,
    this.valueScaleFactor = 1.2,
    this.upgradeCostBase = 100,
    this.abilityFactory,
  });

  PieceStats createStats() => PieceStats(
        maxHp: baseHp,
        currentHp: baseHp,
        attack: baseAttack,
        value: baseValue,
      );

  int getUpgradeCost(int currentLevel) => (upgradeCostBase * (currentLevel * 1.5)).toInt();

  int getStatAtLevel(int base, double scaleFactor, int level) => (base * (1 + scaleFactor * (level - 1))).toInt();
}

// =========================================
//  REGISTRO GLOBALE DEI PEZZI
// =========================================
final Map<PieceType, PieceDefinition> pieceDefinitions = {
  // --- PEZZI BASE ---
  PieceType.pawn: PieceDefinition(
    type: PieceType.pawn,
    baseType: PieceBaseType.pawn,
    displayName: 'Pedone',
    description: 'Il soldato base, muove avanti e cattura in diagonale.',
    baseHp: 30,
    baseAttack: 10,
    baseValue: 5,
    isUnlockable: false,
    upgradeCostBase: 50,
  ),
  PieceType.rook: PieceDefinition(
    type: PieceType.rook,
    baseType: PieceBaseType.rook,
    displayName: 'Torre',
    description: 'Muove in linea retta, alta resistenza.',
    baseHp: 80,
    baseAttack: 25,
    baseValue: 20,
    isUnlockable: false,
    upgradeCostBase: 120,
  ),
  PieceType.knight: PieceDefinition(
    type: PieceType.knight,
    baseType: PieceBaseType.knight,
    displayName: 'Cavallo',
    description: 'Muove a L, può scavalcare i pezzi.',
    baseHp: 50,
    baseAttack: 20,
    baseValue: 15,
    isUnlockable: false,
    upgradeCostBase: 100,
  ),
  PieceType.bishop: PieceDefinition(
    type: PieceType.bishop,
    baseType: PieceBaseType.bishop,
    displayName: 'Alfiere',
    description: 'Muove in diagonale, velocità elevata.',
    baseHp: 45,
    baseAttack: 18,
    baseValue: 12,
    isUnlockable: false,
    upgradeCostBase: 100,
  ),
  PieceType.queen: PieceDefinition(
    type: PieceType.queen,
    baseType: PieceBaseType.queen,
    displayName: 'Regina',
    description: 'Il pezzo più potente, muove in tutte le direzioni.',
    baseHp: 100,
    baseAttack: 40,
    baseValue: 50,
    isUnlockable: false,
    upgradeCostBase: 200,
  ),
  PieceType.king: PieceDefinition(
    type: PieceType.king,
    baseType: PieceBaseType.king,
    displayName: 'Re',
    description: 'Va protetto. La sua caduta significa sconfitta.',
    baseHp: 120,
    baseAttack: 15,
    baseValue: 0, // non genera monete, fine partita
    isUnlockable: false,
    upgradeCostBase: 300,
  ),

  // --- VARIANTI PEDONE ---
  PieceType.fighter: PieceDefinition(
    type: PieceType.fighter,
    baseType: PieceBaseType.pawn,
    displayName: 'Combattente',
    description: 'Variante del pedone con attacco potenziato.',
    baseHp: 35,
    baseAttack: 18,
    baseValue: 8,
    isUnlockable: true,
    unlockCost: 300,
    upgradeCostBase: 70,
    abilityFactory: () => SpecialAbility(
      id: 'battle_cry',
      name: 'Grido di Guerra',
      description: 'Aumenta l\'attacco del 50% per un turno.',
      cooldown: 3,
    ),
  ),
  PieceType.miner: PieceDefinition(
    type: PieceType.miner,
    baseType: PieceBaseType.pawn,
    displayName: 'Minatore',
    description: 'Può piazzare trappole sul terreno.',
    baseHp: 28,
    baseAttack: 12,
    baseValue: 7,
    isUnlockable: true,
    unlockCost: 250,
    upgradeCostBase: 60,
    abilityFactory: () => SpecialAbility(
      id: 'place_trap',
      name: 'Piazza Trappola',
      description: 'Piazza una trappola su una casella adiacente.',
      cooldown: 4,
    ),
  ),
  PieceType.rifleman: PieceDefinition(
    type: PieceType.rifleman,
    baseType: PieceBaseType.pawn,
    displayName: 'Fuciliere',
    description: 'Attacca a distanza di 2 caselle.',
    baseHp: 25,
    baseAttack: 15,
    baseValue: 9,
    isUnlockable: true,
    unlockCost: 350,
    upgradeCostBase: 80,
    abilityFactory: () => SpecialAbility(
      id: 'long_shot',
      name: 'Tiro Lungo',
      description: 'Attacca un pezzo a 3 caselle di distanza.',
      cooldown: 2,
    ),
  ),

  // --- VARIANTI ALFIERE ---
  PieceType.healer: PieceDefinition(
    type: PieceType.healer,
    baseType: PieceBaseType.bishop,
    displayName: 'Curatore',
    description: 'Può ripristinare HP a pezzi alleati.',
    baseHp: 40,
    baseAttack: 10,
    baseValue: 15,
    isUnlockable: true,
    unlockCost: 500,
    upgradeCostBase: 130,
    abilityFactory: () => SpecialAbility(
      id: 'heal',
      name: 'Cura',
      description: 'Ripristina 20 HP a un pezzo alleato adiacente.',
      cooldown: 2,
    ),
  ),
  PieceType.investigator: PieceDefinition(
    type: PieceType.investigator,
    baseType: PieceBaseType.bishop,
    displayName: 'Investigatore',
    description: 'Può rivelare le statistiche dei nemici.',
    baseHp: 42,
    baseAttack: 16,
    baseValue: 14,
    isUnlockable: true,
    unlockCost: 450,
    upgradeCostBase: 120,
    abilityFactory: () => SpecialAbility(
      id: 'reveal',
      name: 'Analisi',
      description: 'Rivela le statistiche di un pezzo nemico per 2 turni.',
      cooldown: 3,
    ),
  ),
  PieceType.invisibleMan: PieceDefinition(
    type: PieceType.invisibleMan,
    baseType: PieceBaseType.bishop,
    displayName: 'Uomo Invisibile',
    description: 'Può rendersi invisibile per un turno.',
    baseHp: 38,
    baseAttack: 22,
    baseValue: 18,
    isUnlockable: true,
    unlockCost: 600,
    upgradeCostBase: 150,
    abilityFactory: () => SpecialAbility(
      id: 'invisibility',
      name: 'Invisibilità',
      description: 'Diventa invisibile al nemico per 1 turno.',
      cooldown: 4,
    ),
  ),

  // --- VARIANTI REGINA ---
  PieceType.warlord: PieceDefinition(
    type: PieceType.warlord,
    baseType: PieceBaseType.queen,
    displayName: 'Condottiera',
    description: 'Potenzia i pezzi alleati nelle vicinanze.',
    baseHp: 95,
    baseAttack: 35,
    baseValue: 55,
    isUnlockable: true,
    unlockCost: 1200,
    upgradeCostBase: 250,
    abilityFactory: () => SpecialAbility(
      id: 'battle_command',
      name: 'Comando Bellico',
      description: 'Tutti i pezzi alleati nel raggio di 2 guadagnano +5 ATK per 2 turni.',
      cooldown: 5,
    ),
  ),
  PieceType.heartQueen: PieceDefinition(
    type: PieceType.heartQueen,
    baseType: PieceBaseType.queen,
    displayName: 'Regina di Cuori',
    description: 'Salute elevatissima, può rigenerare HP.',
    baseHp: 150,
    baseAttack: 25,
    baseValue: 60,
    isUnlockable: true,
    unlockCost: 1500,
    upgradeCostBase: 280,
    abilityFactory: () => SpecialAbility(
      id: 'royal_aura',
      name: 'Aura Regale',
      description: 'Rigenera 15 HP a tutti i pezzi alleati adiacenti.',
      cooldown: 3,
    ),
  ),
  PieceType.soulReaper: PieceDefinition(
    type: PieceType.soulReaper,
    baseType: PieceBaseType.queen,
    displayName: 'Rapitrice di Anime',
    description: 'Ruba HP dai nemici eliminati.',
    baseHp: 90,
    baseAttack: 50,
    baseValue: 65,
    isUnlockable: true,
    unlockCost: 2000,
    upgradeCostBase: 300,
    abilityFactory: () => SpecialAbility(
      id: 'soul_steal',
      name: 'Furto d\'Anima',
      description: 'Ruba il 30% degli HP massimi di un pezzo nemico adiacente.',
      cooldown: 4,
    ),
  ),

  // --- VARIANTI TORRE ---
  PieceType.catapult: PieceDefinition(
    type: PieceType.catapult,
    baseType: PieceBaseType.rook,
    displayName: 'Catapulta',
    description: 'Alto attacco, può colpire a distanza.',
    baseHp: 60,
    baseAttack: 45,
    baseValue: 25,
    isUnlockable: true,
    unlockCost: 700,
    upgradeCostBase: 160,
    abilityFactory: () => SpecialAbility(
      id: 'bombardment',
      name: 'Bombardamento',
      description: 'Attacca tutte le caselle in una riga o colonna.',
      cooldown: 5,
    ),
  ),
  PieceType.ironWall: PieceDefinition(
    type: PieceType.ironWall,
    baseType: PieceBaseType.rook,
    displayName: 'Muro di Ferro',
    description: 'HP massivi, blocca il passaggio nemico.',
    baseHp: 200,
    baseAttack: 15,
    baseValue: 22,
    isUnlockable: true,
    unlockCost: 800,
    upgradeCostBase: 170,
    abilityFactory: () => SpecialAbility(
      id: 'fortify',
      name: 'Fortifica',
      description: 'Riduce i danni subiti del 50% fino al prossimo turno.',
      cooldown: 3,
    ),
  ),

  // --- VARIANTI CAVALLO ---
  PieceType.paladin: PieceDefinition(
    type: PieceType.paladin,
    baseType: PieceBaseType.knight,
    displayName: 'Paladino',
    description: 'Equilibrio perfetto tra attacco e difesa.',
    baseHp: 70,
    baseAttack: 28,
    baseValue: 20,
    isUnlockable: true,
    unlockCost: 600,
    upgradeCostBase: 140,
    abilityFactory: () => SpecialAbility(
      id: 'holy_charge',
      name: 'Carica Sacra',
      description: 'Si muove 2 volte questa mossa, infliggendo +10 danno.',
      cooldown: 3,
    ),
  ),
  PieceType.shadowRider: PieceDefinition(
    type: PieceType.shadowRider,
    baseType: PieceBaseType.knight,
    displayName: 'Cavaliere Ombra',
    description: 'Si muove in silenzio, colpi critici frequenti.',
    baseHp: 45,
    baseAttack: 35,
    baseValue: 18,
    isUnlockable: true,
    unlockCost: 750,
    upgradeCostBase: 160,
    abilityFactory: () => SpecialAbility(
      id: 'shadow_strike',
      name: 'Colpo d\'Ombra',
      description: 'Attacco garantito critico (danno raddoppiato).',
      cooldown: 4,
    ),
  ),
};

// Limiti per tipo base (come negli scacchi standard)
const Map<PieceBaseType, int> pieceMaxCount = {
  PieceBaseType.pawn: 8,
  PieceBaseType.rook: 2,
  PieceBaseType.knight: 2,
  PieceBaseType.bishop: 2,
  PieceBaseType.queen: 1,
  PieceBaseType.king: 1,
};
