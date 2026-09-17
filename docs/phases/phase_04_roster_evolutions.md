# Phase 4 - Roster et evolutions

## Fichiers crees / modifies

- `scripts/autoload/save_manager.gd` : ajout de la logique d'evolution.
  - `get_stage_creature(id)` / `get_xp_investi_creature(id)`.
  - `cout_evolution_vers(stage_cible)` : 300 pour le stade 2, 500 pour le
    stade 3, `-1` sinon (constantes `COUT_EVOLUTION_STAGE_2/3`).
  - `faire_evoluer_creature(id) -> bool` : fait passer la creature au
    stade suivant si assez de XP (deduit le cout, incremente
    `xp_investi`, sauvegarde), sinon ne change rien et retourne `false`.
    **Ne connait pas le stade maximal d'une creature** (separation des
    responsabilites : c'est `creatures.json`/`DataManager` qui le sait,
    pas `SaveManager`) — c'est a l'appelant (l'ecran Roster) de ne pas
    proposer d'evolution au-dela du stade max avant d'appeler cette
    fonction. Si appelee quand meme au-dela, `cout_evolution_vers`
    retourne `-1` et la fonction refuse proprement (pas de crash).
- `scenes/components/CarteCreatureRoster.tscn` +
  `scripts/components/carte_creature_roster.gd` : carte de liste pour
  une creature capturee (sprite au stade actuel + nom), meme langage
  visuel que `CarteMatiere` (cercle blanc, bordure `#CC0000`,
  `BoutonAnime`). Ajoute un etat `definir_selectionnee(bool)` (fond
  teinte rose clair) — la stylebox "selectionnee" est dupliquee depuis
  la stylebox de base (`get_theme_stylebox("normal").duplicate()`) pour
  ne pas modifier la ressource partagee entre toutes les instances
  (meme piege documente pour `CarteMatiere` en Phase 3).
- `scenes/Roster.tscn` + `scripts/roster.gd` : l'ecran complet
  (remplace le placeholder `roster_placeholder.gd`, supprime). Fond a
  bandes diagonales (meme shader que le Hub, coherence visuelle).
  - Liste a gauche (`GrilleCreatures`) : une `CarteCreatureRoster` par
    creature de `SaveManager.get_creatures_capturees()`, selection au
    clic (`selectionnee` signal -> `_selectionner_creature`). La
    premiere creature capturee est selectionnee par defaut.
  - Panneau de details a droite : sprite au stade actuel (ou
    placeholder), nom, "Stade X / Y" (Y = `creature_data.stages`), "XP
    investi : N", bouton "Attribuer XP (cout)" et un label de statut.
  - Le bouton adapte son texte/etat dynamiquement : "Stade maximal
    atteint" (desactive) si `stage_actuel >= stage_max` ; sinon
    "Attribuer XP (300 ou 500)", desactive avec le message "XP
    insuffisant (N requis)" si `SaveManager.get_xp_total() < cout`.
  - Au clic (si eligible) : `SaveManager.faire_evoluer_creature(id)`,
    puis rafraichit le label XP global, le panneau de details (nouveau
    sprite/nom/stade), ET la carte correspondante dans la liste
    (`carte.configurer(...)` avec le nouveau stade) pour que le sprite
    change aussi visible dans la liste sans re-peupler toute la grille.
- `scripts/tests/smoke_test_phase4.gd` : verifie `cout_evolution_vers`,
  le refus sans XP, l'evolution reussie stade 1->2 puis 2->3 (deduction
  XP + cumul `xp_investi`), le refus au-dela du stade max, la
  persistance apres sauvegarde/rechargement, `CarteCreatureRoster` sans
  crash, et la structure de `Roster.tscn`.

## Particularites / decisions

- **Pas de fondu d'entree (`TransitionRadiale`) sur `Roster.tscn`** :
  contrairement a `Hub.tscn`/`DialogueIntro.tscn`, ce n'etait pas
  demande pour cette transition (Hub -> Roster, hors du flux
  menu/chargement/jeu vise par la demande initiale de fondus) — ajoute
  seulement si Mike le demande explicitement plus tard, pour ne pas
  presumer d'un choix esthetique hors scope.
- Mike prevoit de revenir avec des mecaniques "feel good" additionnelles
  pour cet ecran (sans toucher aux sprites) une fois decidees avec
  l'utilisateur — cette phase s'en tient strictement a ce que decrit la
  spec d'origine (section 7) : liste, selection, stats, attribution
  d'XP, evolution par changement de sprite. Ne pas anticiper de
  fonctionnalite non confirmee.

## Verification effectuee

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (autoloads charges) : 0 erreur stderr.
- Suite complete des smoke tests (phase2, phase3, menu_principal,
  raffinements_menu, transition_radiale, hub_style, phase4) : tous
  SUCCES, aucune regression.
- Verification visuelle reelle complete : sauvegarde de test generee
  (starter capture, 300 XP), jeu lance en fenetre sur `Roster.tscn`.
  Premiere capture : liste + panneau de details corrects, carte
  selectionnee visuellement distincte (fond rose), bouton "Attribuer XP
  (300)" actif. **Clic reel simule** sur ce bouton : deuxieme capture
  confirmant l'evolution instantanee — sprite `c1` -> `c2`, nom "Creature
  1" -> "Creature 1 Evo", "Stade 2 / 3", "XP investi : 300", XP total
  passe a 0 en haut-gauche, bouton devient "Attribuer XP (500)"
  desactive avec le message "XP insuffisant (500 requis)", et la carte
  dans la liste a gauche reflete aussi le nouveau sprite/nom.
