# Jeu educatif de mathematiques (2e annee, Quebec)

Godot 4.6, GDScript. Jeu de type "capture de creatures" avec mecaniques
educatives de mathematiques (curriculum 2e annee Quebec). Aucun asset, nom
ou texte Pokemon dans le code : creatures generiques (`c1.png` a
`c151.png`), tout le contenu thematique (noms, niveaux, table de types)
vient de `data/*.json`, fournis par Mike.

Spec complete d'origine : voir le premier message de la session qui a
demarre ce projet (2026-09-17) si besoin de retrouver un detail non
couvert ci-dessous ou dans les archives de phase.

## Etat actuel

**Phase en cours : Phase 1 - Fondations** (structure Godot, sauvegarde,
chargement JSON, ecran titre). Voir section "Phase 1" ci-dessous pour le
detail de ce qui existe déjà.

## Decoupage en phases

1. **Phase 1 - Fondations** (en cours) : structure du projet Godot,
   systeme de sauvegarde, chargement des `data/*.json`, ecran titre.
2. **Phase 2 - Intro et starter** : dialogue narratif, choix du starter
   parmi 3, creation de la sauvegarde initiale.
3. **Phase 3 - Hub principal** : menu des 8 badges/matieres, affichage XP,
   bouton Roster.
4. **Phase 4 - Roster et evolutions** : gestion des creatures, attribution
   d'XP, evolution (300/500 XP).
5. **Phase 5 - Selection de niveau** : 10 tableaux par matiere,
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
testable.

## Phase 1 - ce qui existe deja

- `project.godot` : resolution 1920x1080, autoloads `DataManager`,
  `SaveManager`, `GameState`.
- `scripts/autoload/data_manager.gd` : charge `data/creatures.json`,
  `data/matieres.json`, `data/types.json`, et les fichiers de
  `data/niveaux/*.json` a la demande (`load_niveau(id)`).
- `scripts/autoload/save_manager.gd` : sauvegarde JSON dans
  `user://partie.save` (starter, creatures capturees, creatures vues, XP
  total, progression par matiere/niveau). API : `new_game`, `save_game`,
  `load_game`, `add_xp`, `marquer_vue`, `capturer_creature`,
  `set_progression_niveau`, `est_niveau_debloque`.
- `scripts/autoload/game_state.gd` : etat de session transitoire (matiere/
  niveau courant), pas sauvegarde.
- `scenes/Main.tscn` : point d'entree, redirige vers `MenuPrincipal`.
- `scenes/MenuPrincipal.tscn` : ecran titre (Nouvelle partie / Continuer /
  Quitter). "Continuer" est desactive si aucune sauvegarde n'existe.
- `scenes/DebugEtatSauvegarde.tscn` : ecran **temporaire** qui affiche
  l'etat de la sauvegarde et des donnees chargees, pour valider la
  chaine JSON + sauvegarde. A remplacer par l'intro (Phase 2) et le hub
  (Phase 3) — actuellement "Nouvelle partie" et "Continuer" y menent
  tous les deux.
- `data/creatures.json`, `data/matieres.json`, `data/types.json` :
  placeholders avec quelques entrees d'exemple seulement (Mike doit les
  completer — 81 lignes de creatures au total pour `creatures.json`, 8
  matieres deja completes dans `matieres.json`).
- Dossiers `assets/creatures/`, `assets/backgrounds/`, `assets/ui/`,
  `data/niveaux/` crees (vides, `.gitkeep`).

### Prochaine etape (Phase 2)

Construire l'intro narrative (boite de dialogue texte progressif) et
l'ecran de choix du starter parmi 3 creatures (image + nom + description,
tirees de `data/creatures.json`). Remplacer le flux actuel de
"Nouvelle partie" (qui va directement vers `DebugEtatSauvegarde`) par
cet enchainement, puis vers le hub (Phase 3, pas encore construit).
