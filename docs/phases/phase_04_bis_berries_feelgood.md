# Phase 4 bis - Mecaniques "feel good" + systeme de berries

Suite de la Phase 4 ([phase_04_roster_evolutions.md](phase_04_roster_evolutions.md)).
Mike a valide des mecaniques "feel good" pour le Roster et ajoute un
systeme de berries (baies) plus consequent. Plusieurs choix de
conception n'etaient pas entierement precises dans la demande —
tranches ici et documentes comme demande explicitement ("trancher soi-
meme raisonnablement plutot que bloquer").

## 1. Surnom

- `SaveManager` : champ `"surnom"` ajoute a chaque entree de
  `creatures_capturees` (defaut `""`). `get_surnom_creature(id)` /
  `definir_surnom_creature(id, surnom)` (le surnom est nettoye via
  `strip_edges()`).
- UI : un seul `LineEdit` (`%LineEditSurnom`) remplace l'ancien
  `LabelNomDetail` — son `placeholder_text` est le nom d'espece (affiche
  en gris tant qu'aucun surnom n'est defini, comportement natif de
  Godot), son `text` est le surnom sauvegarde. Sauvegarde sur
  `text_submitted` (touche Entree) et sur `focus_exited` (clic
  ailleurs), pas de bouton "Valider" separe.
- Le surnom (si defini) remplace le nom d'espece dans la carte de liste
  (`CarteCreatureRoster`) — `roster.gd` lit `SaveManager.get_surnom_creature()`
  apres chaque `carte.configurer()` et ecrase `%LabelNom` au besoin
  (plus simple que d'ajouter un parametre supplementaire au composant).

## 2. Barre XP animee

**Decision de conception** : la spec ne prevoit pas qu'une creature
accumule de l'XP progressivement (l'evolution est un paiement immediat
et complet de 300 ou 500 XP pris sur le pool global du joueur). La
barre visualise donc **la progression du joueur vers le prochain
palier d'evolution** : `min(SaveManager.get_xp_total(), cout) / cout`.
Remplace l'ancien texte "XP investi : N" par une `ProgressBar` stylee
(`%BarreXp`) avec un `Label` superpose (`%LabelBarreXpTexte`, "150 / 300
XP"). Se met a jour a chaque changement d'XP (attribution, retour au
panneau apres selection) — la barre elle-meme n'est pas animee image
par image (`ProgressBar.value` change instantanement), ce qui suffit
puisque Godot interpole deja visuellement le remplissage ; l'aspect
"anime" demande par Mike vient surtout de la pulsation/particules du
point 3 au moment ou la valeur change vraiment (attribution d'XP).

## 3. Animation a l'attribution d'XP

`roster.gd::_jouer_effet_attribution_xp()` : pulsation du sprite
(`ZoneSprite.scale` 1.0 -> 1.18 -> 1.0, `Tween` `TRANS_BACK`/`EASE_OUT`)
+ `CPUParticles2D` (`%ParticulesXp`, jaune/or, `one_shot`, 18
particules) positionne au centre de `ZoneSprite`. `pivot_offset` de
`ZoneSprite` et position des particules recalcules dynamiquement
(`resized` signal) car la largeur du panneau n'est pas fixe.

## 4. Systeme de berries

### Modele de donnees (choisi, documente)

- `data["berries_inventaire"]` : `Array[int]`, un element par berry
  possedee, valeur = skin (1 a 10). Pas de structure plus riche (pas
  d'id unique par berry) car les berries sont strictement identiques
  entre elles hormis leur skin cosmetique — un simple tableau de skins
  suffit et simplifie tout le reste (consommation = retrait par index).
- `creatures_capturees[id]["berries_recues"]` : compteur cumulatif
  d'affection (pas de plafond stocke — le plafond visuel a 20 est
  applique a l'affichage, `min(affection, SEUIL_GLOW)`, la valeur brute
  continue de s'incrementer au-dela si jamais redonnee, sans effet
  supplementaire).
- **Pourquoi dans `creatures_capturees` plutot qu'un dictionnaire
  separe** : coherence avec `stage`/`xp_investi`/`surnom`, tout l'etat
  "par creature" reste au meme endroit.

### SaveManager - nouvelles methodes

- `get_berries_inventaire() -> Array` : retourne les skins normalises
  en `int` (voir piege ci-dessous).
- `ajouter_berry(skin: int = -1) -> int` : ajoute une berry (skin
  aleatoire si omis, via `BerryAssetUtil.skin_aleatoire()`), retourne
  le skin ajoute. Utilise par le bouton de debug ET par la future
  distribution de fin de tableau (Phase 6).
- `consommer_berry(index_inventaire: int) -> bool` : retire une berry
  de l'inventaire par index, `false` si index invalide.
- `get_affection_creature(id) -> int`, `est_glow_creature(id) -> bool`
  (>= `SEUIL_GLOW` = 20), `donner_berry_a_creature(id) -> int`
  (incremente et retourne la nouvelle affection).

**Piege trouve et corrige** (par le smoke test, pas devine) : apres un
aller-retour JSON (sauvegarde puis rechargement), les entiers d'un
`Array` reviennent en `float` (JSON ne distingue pas int/float). Une
comparaison stricte de tableau comme `[9] == [9.0]` est **fausse** en
GDScript pour le *contenu* d'un `Array` (contrairement a `9 == 9.0`
qui, elle, est vraie) — piege distinct de celui deja connu sur les
valeurs scalaires (`get_stage_creature` etc. utilisaient deja `int(...)`
pour s'en proteger, mais `get_berries_inventaire()` ne le faisait pas
initialement). Corrige : `get_berries_inventaire()` normalise chaque
element via `int(...)` avant de le retourner.

### Assets remplacables

- `assets/ui/berries/berry1.png` a `berry10.png` (96x96, PNG
  transparent) — voir `assets/ui/berries/LISEZ-MOI.txt`. Placeholder
  tant qu'absents : rond colore, teinte differente par skin
  (`BerryAssetUtil.couleur_placeholder()`, HSV reparti sur les 10
  skins) pour rester distinguables meme sans art.
- **Sprites "glow"** : meme dossier plat que les sprites normaux
  (`assets/creatures/`), suffixe `_glow` sur l'id existant (ex.
  `c1_glow.png` a cote de `c1.png`) — choix documente dans
  `data/creatures.json` (commentaire `_commentaire` mis a jour). Pas de
  sous-dossier separe : reutilise exactement le meme mecanisme de
  resolution que `SpriteUtil` (juste un id different), donc aucune
  nouvelle infrastructure necessaire cote outillage. Nouvelles
  fonctions dans `scripts/util/sprite_util.gd` :
  `id_glow(sprite_id)`, `charger_texture_avec_glow(sprite_id, est_glow)`
  (repli silencieux sur le sprite normal si le glow n'existe pas encore),
  `glow_manquant(sprite_id, est_glow)` (pour afficher un placeholder
  "glow" distinct — halo dore + suffixe "(glow)" — une fois le seuil
  atteint mais avant que Mike ne depose le vrai fichier).

### Composants

- `scenes/components/BerryItem.tscn` + `scripts/components/berry_item.gd` :
  icone draggable (`_get_drag_data`). La charge utile du drag
  (`{"type": "berry", "index_inventaire": ..., "skin": ...}`) est
  construite par une fonction pure separee, `construire_charge_utile()`,
  **specifiquement pour rester testable** : `set_drag_preview()` exige
  d'etre appelee pendant un vrai gste de glisser-depose (erreur moteur
  "!is_inside_tree()" sinon), donc pas appelable directement dans un
  smoke test headless — seule la construction des donnees l'est.
- `scripts/components/zone_drop_creature.gd`
  (`class_name ZoneDropCreature`, `extends Control`) : cible de drop
  generique, filtre `data.type == "berry"` et relaie via le signal
  `berry_deposee(donnees)`. Attache a `%ZoneSprite` dans `Roster.tscn`
  (toute la zone du sprite est la cible, pas juste l'image elle-meme —
  ses enfants (`Halo`, `TextureDetail`, `PlaceholderDetail`, ...) ont
  tous `mouse_filter = 2` (IGNORE) pour laisser passer le drop jusqu'a
  `ZoneSprite`).
- `shaders/halo_lumineux.gdshader` : halo radial blanc/rose (meme
  principe de degrade que `transition_radiale_blanc.gdshader`, un seul
  uniforme `intensite` 0..1). Anime 0 -> 1 (0.15s) -> 0 (0.7s) au drop
  d'une berry, derriere le sprite (`%Halo`, premier enfant de
  `ZoneSprite`).

### Logique de drop (`roster.gd::_on_berry_deposee`)

1. `SaveManager.consommer_berry(index)` (echoue silencieusement si
   l'index n'est plus valide, ex. drops rapides successifs).
2. `SaveManager.donner_berry_a_creature(id)` -> nouvelle affection.
3. Rafraichit l'inventaire affiche, la barre d'affection.
4. Effet stretch (scale elastique `TRANS_ELASTIC`) + halo (voir
   ci-dessus) via `_jouer_effet_berry()`.
5. Si l'affection vient d'atteindre exactement `SEUIL_GLOW` :
   message "Sprite glow debloque !" + `_actualiser_details()` (recharge
   le sprite, qui bascule automatiquement sur
   `charger_texture_avec_glow()`), sinon rafraichit juste la carte de
   liste (sprite/nom potentiellement inchanges).

### Distribution reelle (Phase 6, PAS encore branchee)

La distribution "1 berry par bonne reponse, jusqu'a 10 par tableau" se
fera en Phase 6 (scenes de tableau, pas encore construites) via
`SaveManager.ajouter_berry()` appele une fois par bonne reponse. **En
attendant**, un bouton de debug est present sur l'ecran Roster
(`%BoutonDebugBerry`, libelle "[DEBUG] +1 berry") qui appelle
`SaveManager.ajouter_berry()` (skin aleatoire) pour permettre de tester
tout le systeme des maintenant. **A retirer ou masquer derriere un flag
de debug quand la Phase 6 branchera la vraie distribution** — note
laissee ici pour ne pas l'oublier.

## Verification effectuee

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (autoloads charges) : 0 erreur stderr.
- Suite complete des smoke tests (8 fichiers, dont le nouveau
  `smoke_test_berries.gd`) : tous SUCCES, aucune regression.
  `smoke_test_berries.gd` couvre : surnom (definition + nettoyage),
  inventaire (ajout/consommation/bornes), affection cumulee + seuil
  glow, persistance complete apres reload (ce test a mis en evidence le
  piege int/float ci-dessus), `BerryAssetUtil`, resolution glow de
  `SpriteUtil`, `BerryItem.construire_charge_utile()`,
  `ZoneDropCreature` (filtrage + relai de signal).
- Verification visuelle reelle complete, en conditions quasi-jeu :
  sauvegarde de test generee (starter, 120 XP, 6 berries de skins
  varies), jeu lance en fenetre sur `Roster.tscn`.
  - Capture 1 : barre XP (120/300) et barre d'affection (0/20)
    affichees correctement, 6 berries aux couleurs distinctes dans
    l'inventaire.
  - Saisie reelle d'un surnom ("Bubulle") au clavier simule + Entree :
    carte de liste mise a jour instantanement.
  - **Glisser-depose reel simule** (mouse down sur une berry, 20 pas de
    mouvement vers la creature, mouse up) : capture pendant le drag
    montrant l'apercu de la berry suivant le curseur ; capture apres le
    drop confirmant la berry retiree de l'inventaire (6 -> 5) et la
    barre d'affection passee a 1/20.
  - Clic reel sur "Attribuer XP" (sauvegarde separee a 300 XP) :
    capture montrant les particules jaunes en plein eclatement pendant
    la pulsation du sprite, evolution confirmee (c1 -> c2).
