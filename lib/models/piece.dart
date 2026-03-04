// lib/models/piece.dart

enum PieceType {
  // Pezzi standard
  pawn,
  rook,
  knight,
  bishop,
  queen,
  king,
  // Pezzi sbloccabili - Varianti Pedone
  fighter,      // variante pedone
  miner,        // variante pedone
  rifleman,     // variante pedone
  // Varianti Torre
  catapult,
  ironWall,
  // Varianti Cavallo
  paladin,
  shadowRider,
  // Varianti Alfiere
  healer,
  investigator,
  invisibleMan,
  // Varianti Regina
  warlord,
  heartQueen,
  soulReaper,
  // Varianti Re
  commander,
  // Aggiungi nuovi pezzi qui in futuro...
}

enum PieceBaseType {
  pawn,
  rook,
  knight,
  bishop,
  queen,
  king,
}

enum PlayerSide { player1, player2 }

class PieceStats {
  final int maxHp;
  int currentHp;
  final int attack;
  final int value; // valore in monete quando viene eliminato
  int hpLevel;
  int attackLevel;
  int valueLevel;

  PieceStats({
    required this.maxHp,
    required this.currentHp,
    required this.attack,
    required this.value,
    this.hpLevel = 1,
    this.attackLevel = 1,
    this.valueLevel = 1,
  });

  bool get isHalfHp => currentHp <= maxHp / 2;
  bool get isDead => currentHp <= 0;

  PieceStats copyWith({
    int? maxHp,
    int? currentHp,
    int? attack,
    int? value,
    int? hpLevel,
    int? attackLevel,
    int? valueLevel,
  }) {
    return PieceStats(
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      attack: attack ?? this.attack,
      value: value ?? this.value,
      hpLevel: hpLevel ?? this.hpLevel,
      attackLevel: attackLevel ?? this.attackLevel,
      valueLevel: valueLevel ?? this.valueLevel,
    );
  }
}

class SpecialAbility {
  final String id;
  final String name;
  final String description;
  final int cooldown; // turni di cooldown, 0 = sempre disponibile
  int currentCooldown;

  SpecialAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.cooldown,
    this.currentCooldown = 0,
  });

  bool get isReady => currentCooldown == 0;
}

class Piece {
  final String id; // ID univoco istanza
  final PieceType type;
  final PieceBaseType baseType;
  final PlayerSide side;
  PieceStats stats;
  final SpecialAbility? specialAbility;
  String? equippedSkin; // ID della skin equipaggiata
  bool hasMoved; // per castling e mosse speciali

  Piece({
    required this.id,
    required this.type,
    required this.baseType,
    required this.side,
    required this.stats,
    this.specialAbility,
    this.equippedSkin,
    this.hasMoved = false,
  });

  // Immagine da mostrare in base alla vita
  String get imagePath {
    final skinPrefix = equippedSkin != null ? 'skins/${equippedSkin}_' : 'pieces/';
    final suffix = stats.isHalfHp ? '_half' : '_full';
    return 'assets/images/$skinPrefix${type.name}$suffix.png';
  }

  Piece copyWith({
    PieceStats? stats,
    String? equippedSkin,
    bool? hasMoved,
  }) {
    return Piece(
      id: id,
      type: type,
      baseType: baseType,
      side: side,
      stats: stats ?? this.stats,
      specialAbility: specialAbility,
      equippedSkin: equippedSkin ?? this.equippedSkin,
      hasMoved: hasMoved ?? this.hasMoved,
    );
  }
}
