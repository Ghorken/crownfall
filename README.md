# Crown Fall 🏰⚔️

Gioco di scacchi modificato con elementi RPG in stile Clash Royale, sviluppato in Flutter.

## 📁 Struttura del Progetto

```
crownfall/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── models/
│   │   ├── piece.dart                     # Classi Piece, PieceStats, SpecialAbility
│   │   ├── piece_definitions.dart         # Configurazione di tutti i pezzi
│   │   ├── board.dart                     # Scacchiera e Position
│   │   └── player_profile.dart            # Profilo, inventario, esercito
│   ├── providers/
│   │   ├── game_provider.dart             # Logica di gioco (state management)
│   │   └── shop_provider.dart             # Negozio, upgrades, skin
│   ├── services/
│   │   ├── movement_service.dart          # Regole di movimento
│   │   └── combat_service.dart            # Meccanica combattimento
│   ├── widgets/
│   │   ├── piece_widget.dart              # Widget pezzo + placeholder painter
│   │   └── game_board_widget.dart         # Griglia scacchiera
│   └── screens/
│       ├── main_menu_screen.dart          # Menu principale
│       ├── game_screen.dart               # Schermata di gioco
│       ├── shop_screen.dart               # Negozio
│       └── army_builder_screen.dart       # Costruttore esercito
└── assets/
    └── images/
        ├── pieces/      ← Qui vanno le immagini dei pezzi
        ├── ui/          ← Icone e grafica interfaccia
        ├── skins/       ← Skin alternative dei pezzi
        └── boards/      ← Texture alternative per la scacchiera
```

---

## 🖼️ Come Sostituire i Placeholder con Asset Reali

### Convenzione Nomi File

Per ogni pezzo servono **2 immagini**:
```
assets/images/pieces/{piece_id}_full.png   → vita piena (> 50%)
assets/images/pieces/{piece_id}_half.png   → vita ridotta (≤ 50%)
```

**Lista degli ID pezzi** (`piece_id`):
| ID              | Pezzo                |
|-----------------|----------------------|
| `pawn`          | Pedone               |
| `rook`          | Torre                |
| `knight`        | Cavallo              |
| `bishop`        | Alfiere              |
| `queen`         | Regina               |
| `king`          | Re                   |
| `fighter`       | Combattente          |
| `miner`         | Minatore             |
| `rifleman`      | Fuciliere            |
| `catapult`      | Catapulta            |
| `ironWall`      | Muro di Ferro        |
| `paladin`       | Paladino             |
| `shadowRider`   | Cavaliere Ombra      |
| `healer`        | Curatore             |
| `investigator`  | Investigatore        |
| `invisibleMan`  | Uomo Invisibile      |
| `warlord`       | Condottiera          |
| `heartQueen`    | Regina di Cuori      |
| `soulReaper`    | Rapitrice di Anime   |
| `commander`     | Comandante           |

### Come Distinguere i Giocatori Senza Bianchi/Neri

Nei file `piece_widget.dart` i pezzi vengono identificati con:
- **Bordo ciano** → Giocatore 1 (tu)
- **Bordo rosso** → Giocatore 2 (avversario)

Quando inserisci asset reali, puoi fare in due modi:
1. **Un'unica immagine per pezzo** + bordo colorato gestito dal codice (già implementato)
2. **Due varianti** `{piece_id}_p1_full.png` e `{piece_id}_p2_full.png` con colori diversi

### Dove Modificare il Codice per Usare Asset Reali

In `lib/widgets/piece_widget.dart`, nel metodo `build` della classe `PieceWidget`:

```dart
// PRIMA (placeholder):
_buildPlaceholder(),

// DOPO (asset reali):
Image.asset(
  piece.imagePath,  // già calcolato automaticamente
  fit: BoxFit.contain,
  errorBuilder: (_, __, ___) => _buildPlaceholder(), // fallback se manca
),
```

Puoi anche lasciare `errorBuilder` che usa il placeholder come fallback
mentre aggiungi le immagini gradualmente.

### Skin dei Pezzi

Per le skin, la convenzione è:
```
assets/images/skins/{skin_id}_{piece_id}_full.png
assets/images/skins/{skin_id}_{piece_id}_half.png
```
Es: `assets/images/skins/army_fire_pawn_full.png`

Il path viene calcolato automaticamente in `Piece.imagePath`.

---

## 🎮 Funzionalità Implementate

### Meccanica di Gioco
- ✅ Scacchiera 8x8 con coordinate
- ✅ Movimento valido per tutti i tipi base (pedone, torre, alfiere, cavallo, regina, re)
- ✅ **Combattimento**: quando un pezzo attacca, entrambi si infliggono danni simultaneamente
- ✅ Logica di posizionamento dopo il combattimento (attaccante torna alla casella libera più vicina se entrambi sopravvivono)
- ✅ Guadagno monete per eliminazione pezzi
- ✅ Rilevamento vittoria (re eliminato)
- ✅ Premio monete vittoria/sconfitta
- ✅ Selezione pezzo e visualizzazione mosse valide
- ✅ Turni alternati
- ✅ Nel turno: mossa + abilità speciale (in ordine qualsiasi)

### Pezzi
- ✅ 6 pezzi base
- ✅ 14 pezzi sbloccabili con abilità speciali
- ✅ Statistiche HP/ATK/Valore per ogni pezzo
- ✅ Immagine diversa a metà vita (placeholder con crepa visiva)
- ✅ Le statistiche del tuo giocatore sono visibili, quelle nemiche no

### Negozio
- ✅ Sblocco nuovi pezzi con monete
- ✅ Upgrade di HP, ATK, Valore per ogni pezzo (scalano diversamente)
- ✅ Potenziamento Iniziativa
- ✅ Acquisto Skin (per singoli pezzi o intera armata)

### Esercito
- ✅ Composizione esercito personalizzata
- ✅ Rispetto limiti per tipo base (max 8 pedoni, 2 torri, ecc.)
- ✅ Mix di varianti (es: 3 pedoni + 2 combattenti + 2 fucilieri + 1 minatore)

---

## 🔮 Espansione Futura

### Aggiungere Nuovi Pezzi
1. Aggiungi il valore a `PieceType` enum in `piece.dart`
2. Aggiungi la definizione in `pieceDefinitions` in `piece_definitions.dart`
3. Aggiungi il `PieceBaseType` se è una nuova categoria
4. Aggiorna `pieceMaxCount` se necessario
5. Aggiungi le immagini in `assets/images/pieces/`

### Aggiungere Nuove Modalità di Gioco
Crea una nuova schermata es. `capture_the_flag_screen.dart` e un provider dedicato.
Il `MovementService` e `CombatService` sono riusabili.

### Aggiungere Abilità Speciali
Implementa la logica in `game_provider.dart` nel metodo `useAbility()`.
Le abilità sono già definite per ogni pezzo, manca solo l'effetto concreto.

### Multiplayer Online
Sostituisci la logica "turno avversario" in `GameProvider` con chiamate a un backend/socket.

---

## 🚀 Setup

```bash
flutter pub get
flutter run
```

Dimensioni consigliate per le immagini: **128x128px** o **256x256px** in PNG con sfondo trasparente.
