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

**Phases 1 a 6 (+ 4 bis) terminees et verifiees** (voir archives
ci-dessous). Prochaine etape : **Phase 7 - Logique de rencontre/capture**.

**Important pour la Phase 7** :
- Dans `scenes/EcranTableau.tscn`, `ZoneSauvage` affiche un placeholder
  fixe `"? (Phase 7)"` — a remplacer par la vraie creature sauvage
  tiree au hasard (section 9.1 de la spec : parmi les non-evoluees
  jamais vues, `SaveManager.get_creatures_vues()` /
  `DataManager.get_creatures_non_evoluees()`).
- Brancher la capture reelle en fin de tableau reussi (>=7/10) dans
  `scripts/ecran_tableau.gd::_terminer_tableau()` :
  `SaveManager.capturer_creature()` + `SaveManager.marquer_vue()`.
  `capturer_creature()` avait un bug (ne sauvegardait jamais) trouve et
  corrige pendant l'ajout de la "creature principale" — voir
  [docs/phases/phase_06_scenes_tableau.md](docs/phases/phase_06_scenes_tableau.md).
- Cote joueur, `EcranTableau` affiche deja la "creature principale"
  choisie au Roster (`SaveManager.get_creature_principale_id()`), rien
  a faire de ce cote pour la Phase 7.

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
   berries avec glisser-depose et sprites "glow").
5. **Phase 5 - Selection de niveau** — termine, voir
   [docs/phases/phase_05_selection_niveau.md](docs/phases/phase_05_selection_niveau.md).
6. **Phase 6 - Scenes de tableau** — termine, voir
   [docs/phases/phase_06_scenes_tableau.md](docs/phases/phase_06_scenes_tableau.md)
   (8 widgets de reponse reutilisables + orchestrateur commun, 80
   niveaux de contenu, XP/berries branches pour de vrai).
7. **Phase 7 - Logique de rencontre/capture** (prochaine) : distribution
   aleatoire des 80 creatures restantes sans repetition, integree a la
   sauvegarde.
8. **Phase 8 - Polish et integration finale** : transitions fade
   in/out, tests de bout en bout, remplacement des placeholders par
   vrais assets si disponibles.

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

## Prochaine etape : Phase 7 - Logique de rencontre/capture

A construire (voir section 9.1 de la spec d'origine) :
- Distribution aleatoire des 80 creatures non-evoluees restantes (81 -
  1 starter), sans repetition tant que toutes n'ont pas ete vues :
  piocher parmi `DataManager.get_creatures_non_evoluees()` moins
  `SaveManager.get_creatures_vues()` (si cette liste est vide, la
  reinitialiser implicitement en repiochant parmi toutes).
- Afficher la creature sauvage tiree dans `ZoneSauvage` de
  `scenes/EcranTableau.tscn` (actuellement un placeholder fixe) —
  fixee au debut du tableau (`GameState` ou directement au `_ready()`
  de `ecran_tableau.gd`), la meme tout au long des 10 questions.
- A la reussite du tableau (>=7/10) : `SaveManager.capturer_creature()`
  + `SaveManager.marquer_vue()`. A l'echec : `marquer_vue()` quand meme
  (vue mais pas capturee, cf. section 9.1 de la spec), pas de capture.
- Penser a un smoke test headless (`scripts/tests/smoke_test_phase7.gd`).
