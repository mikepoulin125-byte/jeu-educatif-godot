# Jeu educatif de mathematiques (2e annee, Quebec)

Godot 4.6, GDScript. Jeu de type "capture de creatures" avec mecaniques
educatives de mathematiques (curriculum 2e annee Quebec). Aucun asset, nom
ou texte Pokemon dans le code : creatures generiques (`c1.png` a
`c151.png`), tout le contenu thematique (noms, niveaux, table de types)
vient de `data/*.json`, fournis par Mike.

Spec complete d'origine : voir le premier message de la session qui a
demarre ce projet (2026-09-17) si besoin de retrouver un detail non
couvert ci-dessous ou dans les archives de phase.

Godot 4.6.3 est installe sur la machine
(`%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe`, installe via winget).
Toujours verifier une phase avec
`godot --headless --path <projet_racine> --import` (0 erreur attendue)
avant de la considerer terminee. Le dossier `scripts/tests/` contient des
scripts de smoke test headless (`godot --headless --script res://scripts/tests/<nom>.gd`) —
en ajouter un par phase qui touche a de la logique non triviale, et le
relancer si le code concerne est modifie plus tard.

## Etat actuel

**Phases 1 a 7 (+ 4 bis) terminees et verifiees** (voir archives
ci-dessous) — toutes les mecaniques de jeu de la spec d'origine sont
maintenant fonctionnelles de bout en bout (menu -> hub -> tableaux ->
rencontre/capture -> roster). Prochaine et derniere etape : **Phase 8 -
Polish et integration finale**.

**Important pour la Phase 8** :
- Transitions fade in/out : le composant `TransitionRadiale`
  (`scenes/components/TransitionRadiale.tscn`) existe deja et est
  utilise sur certains ecrans (Menu, Hub, DialogueIntro,
  SelectionNiveau) mais pas tous (ex. Roster, EcranTableau) —
  generaliser si Mike le souhaite.
- Remplacement des placeholders par les vrais assets des que Mike les
  fournit (`assets/creatures/*.png`, `assets/ui/**/*.png`,
  `assets/audio/ui/*.ogg`) — tout le mecanisme de repli est deja en
  place (`SpriteUtil`, `UiIconUtil`, `BerryAssetUtil`, `AudioManager`),
  aucun code a changer normalement.
- 79 des 80 fichiers de niveaux (`data/niveaux/*.json`) ont un contenu
  fonctionnel mais genere via script (voir
  [docs/phases/phase_06_scenes_tableau.md](docs/phases/phase_06_scenes_tableau.md)) —
  un peu repetitif par endroits. A affiner manuellement si souhaite,
  simples fichiers de donnees, aucun impact sur le code.
- Tests de bout en bout supplementaires si de nouveaux cas limites
  emergent en playtest reel avec l'enfant.

**Piege GDScript a connaitre avant de coder un nouveau composant
reutilisable** : ne pas utiliser `@onready var x = %NodeName` pour un
composant configure juste apres `instantiate()`/`add_child()` — resoudre
`%NodeName` a la demande dans la fonction de configuration a la place
(voir [docs/phases/phase_03_hub_principal.md](docs/phases/phase_03_hub_principal.md)
pour le detail du bug — retrouve en Phase 6 sur les 8 widgets de
`scripts/tableau/`, meme cause). Et ne jamais utiliser `assert()` dans
un script de test headless (bloque indefiniment sans debugger attache)
— utiliser un helper `_verifier(condition, message)` qui `print()` +
`quit(1)`.

**Autre piege a connaitre** : un nombre entier lu depuis un fichier
JSON revient en `float` (JSON ne distingue pas int/float). Toujours
passer par `int(...)` avant de **comparer** (`get_stage_creature` etc.,
Phase 4) ET avant d'**afficher** (`str(int(valeur))`, pas `str(valeur)`
— trouve en Phase 6 sur `widget_pair_impair.gd`/
`widget_croissant_decroissant.gd`, affichait "4.0" au lieu de "4").

**Reflexe SaveManager** : toute nouvelle methode qui mute `data` doit
se terminer par `save_game()` — `capturer_creature()` et
`marquer_vue()` ont toutes les deux ete ecrites en Phase 1 sans cet
appel, et le bug est reste invisible (silencieux, pas d'erreur) jusqu'a
ce qu'une phase bien plus tardive les utilise pour de vrai (Phase 6
pour la premiere, Phase 7 pour la seconde). Avant d'ajouter une methode
mutative a `SaveManager`, verifier explicitement l'appel a
`save_game()`.

## Decoupage en phases

1. **Phase 1 - Fondations** — termine, voir
   [docs/phases/phase_01_fondations.md](docs/phases/phase_01_fondations.md).
2. **Phase 2 - Intro et starter** — termine, voir
   [docs/phases/phase_02_intro_starter.md](docs/phases/phase_02_intro_starter.md).
3. **Phase 3 - Hub principal** — termine, voir
   [docs/phases/phase_03_hub_principal.md](docs/phases/phase_03_hub_principal.md).
4. **Phase 4 - Roster et evolutions** — termine, voir
   [docs/phases/phase_04_roster_evolutions.md](docs/phases/phase_04_roster_evolutions.md)
   et [docs/phases/phase_04_bis_berries_feelgood.md](docs/phases/phase_04_bis_berries_feelgood.md)
   (surnom, barre XP animee, animation d'attribution d'XP, systeme de
   berries avec glisser-depose et sprites "glow", creature principale).
5. **Phase 5 - Selection de niveau** — termine, voir
   [docs/phases/phase_05_selection_niveau.md](docs/phases/phase_05_selection_niveau.md).
6. **Phase 6 - Scenes de tableau** — termine, voir
   [docs/phases/phase_06_scenes_tableau.md](docs/phases/phase_06_scenes_tableau.md)
   (8 widgets de reponse reutilisables + orchestrateur commun, 80
   niveaux de contenu, XP/berries branches pour de vrai, creature
   principale affichee cote joueur).
7. **Phase 7 - Logique de rencontre/capture** — termine, voir
   [docs/phases/phase_07_rencontre_capture.md](docs/phases/phase_07_rencontre_capture.md)
   (tirage aleatoire sans repetition, association fixe creature/tableau,
   capture reelle a la reussite).
8. **Phase 8 - Polish et integration finale** (prochaine, derniere) :
   transitions fade in/out generalisees, tests de bout en bout,
   remplacement des placeholders par vrais assets si disponibles.

Une phase = une grande etape ci-dessus (pas de sous-decoupage
documentaire separe).

## Protocole d'archivage (a suivre a CHAQUE phase completee)

1. Archiver les notes techniques de la phase terminee dans
   `docs/phases/phase_NN_nom.md` (decisions techniques, fichiers crees,
   particularites a retenir pour la suite).
2. Nettoyer ce `CLAUDE.md` : ne garder que l'etat actuel (court), la liste
   des phases avec un lien vers leur archive, et les instructions pour la
   phase suivante. Ne jamais laisser le detail technique s'accumuler ici.
3. But : eviter que ce fichier grossisse et gonfle les tokens consommes a
   chaque session.

## Demandes d'assets UI en cours de route

Des qu'une phase a besoin d'un visuel d'UI qui n'existe pas (icone,
bouton, fond, cadre...), s'arreter et le demander a Mike explicitement :
nom de fichier + emplacement attendu, format (PNG transparent, etc.),
dimensions exactes en pixels. En attendant, utiliser un placeholder
(`ColorRect` + texte du nom de fichier attendu) pour que le jeu reste
testable. Note : les sprites de creatures (`assets/creatures/c*.png`)
suivent deja ce patron via `scripts/util/sprite_util.gd`
(`SpriteUtil.charger_texture(id)` retourne `null` si le fichier n'existe
pas encore — au composant appelant d'afficher un placeholder, voir
`scripts/components/carte_creature.gd` pour un exemple).

## Prochaine etape : Phase 8 - Polish et integration finale

Derniere phase du decoupage d'origine. A voir avec Mike ce qu'il
souhaite prioriser parmi :
- Generaliser les transitions `TransitionRadiale` aux ecrans qui n'en
  ont pas encore (Roster, EcranTableau).
- Integrer les vrais assets au fur et a mesure qu'ils sont fournis.
- Repasser sur le contenu genere des niveaux si Mike veut plus de
  variete que ce que le script d'auteur de la Phase 6 a produit.
- Tests de bout en bout / playtest reel avec l'enfant, corriger les
  cas limites qui en ressortiraient.
