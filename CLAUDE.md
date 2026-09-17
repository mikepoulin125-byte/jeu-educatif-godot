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

**Phase 1 et Phase 2 terminees et verifiees** (voir archives ci-dessous).
Prochaine etape : **Phase 3 - Hub principal**, voir section correspondante
plus bas.

## Decoupage en phases

1. **Phase 1 - Fondations** — termine, voir
   [docs/phases/phase_01_fondations.md](docs/phases/phase_01_fondations.md).
2. **Phase 2 - Intro et starter** — termine, voir
   [docs/phases/phase_02_intro_starter.md](docs/phases/phase_02_intro_starter.md).
3. **Phase 3 - Hub principal** (prochaine) : menu des 8 badges/matieres,
   affichage XP, bouton Roster.
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
testable. Note : les sprites de creatures (`assets/creatures/c*.png`)
suivent deja ce patron via `scripts/util/sprite_util.gd`
(`SpriteUtil.charger_texture(id)` retourne `null` si le fichier n'existe
pas encore — au composant appelant d'afficher un placeholder, voir
`scripts/components/carte_creature.gd` pour un exemple).

## Prochaine etape : Phase 3 - Hub principal

A construire (voir section 6 de la spec d'origine) :
- `scenes/Hub.tscn` : 8 boutons/badges (un par matiere de
  `data/matieres.json`), affichage permanent du XP total
  (`SaveManager.get_xp_total()`) en haut a gauche, bouton Roster
  permanent (menant a un ecran Roster pas encore construit — Phase 4,
  laisser un placeholder qui ne fait rien ou log un message pour
  l'instant).
- Remplacer les deux endroits qui redirigent actuellement vers
  `scenes/DebugEtatSauvegarde.tscn` (`scripts/menu_principal.gd` pour
  "Continuer", `scripts/selection_starter.gd` apres le choix du
  starter) par une redirection vers `scenes/Hub.tscn`.
- Clic sur un badge de matiere : fade out/in vers l'ecran de selection de
  niveau (Phase 5, pas encore construit) — pour l'instant, un
  placeholder minimal suffit tant que la Phase 5 n'est pas faite.
