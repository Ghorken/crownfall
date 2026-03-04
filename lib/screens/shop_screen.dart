// lib/screens/shop_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/piece_definitions.dart';
import 'package:crownfall/providers/shop_provider.dart';
import 'package:crownfall/widgets/piece_widget.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Row(
          children: [
            const Text('Negozio', style: TextStyle(color: Colors.amber)),
            const Spacer(),
            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${shop.profile.coins}',
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Pezzi'),
            Tab(text: 'Potenziamenti'),
            Tab(text: 'Skin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PiecesTab(shop: shop),
          _UpgradesTab(shop: shop),
          _SkinsTab(shop: shop),
        ],
      ),
    );
  }
}

// ===== TAB PEZZI =====
class _PiecesTab extends StatelessWidget {
  final ShopProvider shop;
  const _PiecesTab({required this.shop});

  @override
  Widget build(BuildContext context) {
    final unlockable = pieceDefinitions.values.where((d) => d.isUnlockable).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unlockable.length,
      itemBuilder: (context, i) {
        final def = unlockable[i];
        final owned = shop.profile.hasPiece(def.type);
        final canBuy = shop.canUnlock(def.type);

        return Card(
          color: const Color(0xFF16213E),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: SizedBox(
              width: 48,
              height: 48,
              child: owned
                  ? PieceWidget(
                      piece: _dummyPiece(def.type, def.baseType),
                      size: 48,
                    )
                  : _LockedPieceIcon(baseType: def.baseType),
            ),
            title: Text(
              def.displayName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatChip('❤️ ${def.baseHp}'),
                    const SizedBox(width: 4),
                    _StatChip('⚔️ ${def.baseAttack}'),
                    const SizedBox(width: 4),
                    _StatChip('🪙 ${def.baseValue}'),
                  ],
                ),
                if (def.abilityFactory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _StatChip('✨ ${def.abilityFactory!()?.name ?? 'Abilità speciale'}'),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: owned
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: canBuy ? () => _buy(context, shop, def.type) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canBuy ? Colors.amber : Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: Text(
                      '${def.unlockCost}🪙',
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _buy(BuildContext context, ShopProvider shop, PieceType type) {
    final success = shop.unlockPiece(type);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pieceDefinitions[type]!.displayName} sbloccato!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ===== TAB UPGRADES =====
class _UpgradesTab extends StatelessWidget {
  final ShopProvider shop;
  const _UpgradesTab({required this.shop});

  @override
  Widget build(BuildContext context) {
    final owned = shop.profile.unlockedPieces.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Iniziativa
        _InitiativeCard(shop: shop),
        const SizedBox(height: 12),
        const Text('Migliora i pezzi', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...owned.map((type) => _PieceUpgradeCard(shop: shop, type: type)),
      ],
    );
  }
}

class _InitiativeCard extends StatelessWidget {
  final ShopProvider shop;
  const _InitiativeCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F3460),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.yellow),
                const SizedBox(width: 8),
                Text(
                  'Iniziativa: Lvl ${shop.profile.initiative}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Chi ha iniziativa più alta inizia la partita. In caso di parità, si lancia una moneta.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: shop.profile.coins >= shop.initiativeUpgradeCost ? () => shop.upgradeInitiative() : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
              child: Text(
                'Potenzia (${shop.initiativeUpgradeCost}🪙)',
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieceUpgradeCard extends StatelessWidget {
  final ShopProvider shop;
  final PieceType type;
  const _PieceUpgradeCard({required this.shop, required this.type});

  @override
  Widget build(BuildContext context) {
    final def = pieceDefinitions[type]!;
    final levels = shop.profile.getUpgradeLevel(type);

    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(def.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _UpgradeRow(
              label: '❤️ HP',
              level: levels.hpLevel,
              cost: shop.getUpgradeCost(type, 'hp'),
              canAfford: shop.profile.coins >= shop.getUpgradeCost(type, 'hp'),
              onUpgrade: () => shop.upgradeStat(type, 'hp'),
            ),
            _UpgradeRow(
              label: '⚔️ ATK',
              level: levels.attackLevel,
              cost: shop.getUpgradeCost(type, 'attack'),
              canAfford: shop.profile.coins >= shop.getUpgradeCost(type, 'attack'),
              onUpgrade: () => shop.upgradeStat(type, 'attack'),
            ),
            _UpgradeRow(
              label: '🪙 Valore',
              level: levels.valueLevel,
              cost: shop.getUpgradeCost(type, 'value'),
              canAfford: shop.profile.coins >= shop.getUpgradeCost(type, 'value'),
              onUpgrade: () => shop.upgradeStat(type, 'value'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  final String label;
  final int level;
  final int cost;
  final bool canAfford;
  final VoidCallback onUpgrade;

  const _UpgradeRow({
    required this.label,
    required this.level,
    required this.cost,
    required this.canAfford,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Row(
            children: List.generate(
              level.clamp(0, 10),
              (_) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 2),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Text('Lv.$level', style: const TextStyle(color: Colors.amber, fontSize: 10)),
          const Spacer(),
          TextButton(
            onPressed: canAfford ? onUpgrade : null,
            child: Text(
              '+1 ($cost🪙)',
              style: TextStyle(
                color: canAfford ? Colors.cyan : Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== TAB SKIN =====
class _SkinsTab extends StatelessWidget {
  final ShopProvider shop;
  const _SkinsTab({required this.shop});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableSkins.length,
      itemBuilder: (context, i) {
        final skin = availableSkins[i];
        final owned = shop.hasSkin(skin.skinId);
        final canBuy = !owned && shop.profile.coins >= skin.cost;

        return Card(
          color: const Color(0xFF16213E),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: skin.skinId.contains('fire')
                      ? [Colors.orange, Colors.red]
                      : skin.skinId.contains('ice')
                          ? [Colors.cyan, Colors.blue]
                          : [Colors.purple, Colors.deepPurple],
                ),
              ),
              child: Icon(
                skin.targetPiece == null ? Icons.shield : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(skin.name, style: const TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skin.description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                if (skin.targetPiece == null) const Text('Skin per tutta l\'armata', style: TextStyle(color: Colors.amber, fontSize: 10)),
              ],
            ),
            trailing: owned
                ? TextButton(
                    onPressed: () => shop.equipSkin(skin.skinId),
                    child: const Text('Equipaggia', style: TextStyle(color: Colors.cyan)),
                  )
                : ElevatedButton(
                    onPressed: canBuy ? () => shop.buySkin(skin) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canBuy ? Colors.amber : Colors.grey,
                    ),
                    child: Text('${skin.cost}🪙', style: const TextStyle(color: Colors.black, fontSize: 12)),
                  ),
          ),
        );
      },
    );
  }
}

// Helpers
class _StatChip extends StatelessWidget {
  final String label;
  const _StatChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      );
}

class _LockedPieceIcon extends StatelessWidget {
  final PieceBaseType baseType;
  const _LockedPieceIcon({required this.baseType});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.lock, color: Colors.grey, size: 24),
        ),
      );
}

Piece _dummyPiece(PieceType type, PieceBaseType baseType) => Piece(
      id: 'shop_dummy_$type',
      type: type,
      baseType: baseType,
      side: PlayerSide.player1,
      stats: pieceDefinitions[type]!.createStats(),
    );
