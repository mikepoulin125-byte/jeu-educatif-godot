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

**Phases 1 a 4 (+ 4 bis) terminees et verifiees** (voir archives
ci-dessous). Prochaine etape : **Phase 5 - Selection de niveau**.

**Important pour la Phase 6 (scenes de tableau) a venir** : le systeme
de berries (Phase 4 bis) a son infrastructure prete
(`SaveManager.ajouter_berry()`) mais la distribution reelle
("1 berry par bonne reponse, jusqu'a 10 par tableau") n'est PAS encore
branchee — brancher `SaveManager.ajouter_berry()` a chaque bonne
reponse en Phase 6, et retirer/masquer le bouton de debug
`%BoutonDebugBerry` du Roster (`scripts/roster.gd`) une fois que la
vraie distribution fonctionne.

**Piege GDScript a connaitre avant de coder un nouveau composant
reutilisable** : ne pas utiliser `@onready var x = %NodeName` pour un
composant configure juste apres `instantiate()`/`add_child()` — resoudre
`%NodeName` a la demande dans la fonction de configuration a la place
(voir [docs/phases/phase_03_hub_principal.md](docs/phases/phase_03_hub_principal.md)
pour le detail du bug). Et ne jamais utiliser `assert()` dans un script
de test headless (bloque indefiniment sans debugger attache) — utiliser
un helper `_verifier(condition, message)` qui `print()` + `quit(1)`.

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
5. **Phase 5 - Selection de niveau** (prochaine) : 10 tableaux par matiere,
   progression lineaire (deblocage sequentiel, seuil 7/10).
6. **Phase 6 - Scenes de tableau** : les 8 mecaniques d'interaction
   (pair/impair, approximation, terme manquant, plan cartesien,
   possible/impossible, tableau/pictogramme, fractions,
   croissant/decroissant), scoring, XP.
7. **Phase 7 - Logique de rencontre/capture** : distribution aleatoire des
   80 creatures restantes sans repetition, integree a la sauvegarde.
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

## Prochaine etape : Phase 5 - Selection de niveau

A construire (voir section 8 de la spec d'origine) :
- Remplacer le placeholder actuel (`scripts/selection_niveau_placeholder.gd`,
  `scenes/SelectionNiveau.tscn`) par le vrai ecran : 10 boutons de
  niveau pour la matiere choisie (`GameState.matiere_courante_id`),
  noms thematiques a definir, progression strictement lineaire (niveau
  *n+1* debloque seulement si niveau *n* reussi, seuil 7/10 — logique
  deja disponible dans `SaveManager.est_niveau_debloque()` /
  `set_progression_niveau()`, cf. Phase 1).
- Fichiers de niveaux attendus dans `data/niveaux/matiere_XX_niveau_YY.json`
  (actuellement vide) : a creer au moins un exemple pour tester le flux
  de bout en bout avant la Phase 6 (scenes de tableau).
- Fade in/out entre le Hub et cet ecran : voir le composant
  `TransitionRadiale` (Phase 3/raffinements) si Mike souhaite la meme
  coherence visuelle qu'ailleurs.
- Penser a un smoke test headless (`scripts/tests/smoke_test_phase5.gd`).
