# Phase 7 - Logique de rencontre/capture

## Fichiers crees / modifies

- **`scripts/util/rencontre_util.gd`** (`class_name RencontreUtil`) :
  fonction pure `tirer_creature_sauvage(toutes_ids, deja_vues)` — tire
  une creature parmi celles non-evoluees jamais vues, sans repetition
  tant que toutes n'y sont pas passees (section 9.1 de la spec). Prend
  les deux listes en parametres plutot que de lire les autoloads
  directement, pour rester testable sans dependre de `DataManager`/
  `SaveManager`. **Decision documentee** pour le cas "toutes les
  creatures ont deja ete vues" (non precise explicitement par la
  spec) : retire alors parmi l'ensemble complet plutot que de bloquer
  — garantit qu'un tirage reste toujours possible.
- **`SaveManager`** :
  - `get_creature_rencontre(tableau_id)` /
    `definir_creature_rencontre(tableau_id, creature_id)` : memorise
    quelle creature sauvage est associee a QUEL tableau precis
    (`"{matiere_id}_{niveau_id}"`). **Decision de conception
    importante** : le tirage n'a lieu qu'**une seule fois** par
    tableau, la premiere fois qu'il est visite — les visites suivantes
    (retente apres un echec, ou meme apres une reussite) retrouvent la
    meme creature. Necessaire pour respecter la spec : "le tableau est
    rate, la creature reste vue mais pas capturee ; a revisiter... la
    meme creature apparait puisque le tableau/les questions sont
    scriptes" (section 9.1).
- **`scripts/ecran_tableau.gd`** :
  - `_preparer_rencontre()` (appelee dans `_ready()`, apres l'affichage
    de la creature du joueur) : recupere ou tire la creature sauvage du
    tableau courant, la marque vue (`SaveManager.marquer_vue()`), et
    l'affiche.
  - `_afficher_creature_sauvage()` : meme mecanisme sprite/placeholder
    que partout ailleurs dans le projet (`SpriteUtil.charger_texture()`),
    **toujours au stade 1** (`forms.stage1`) puisqu'une creature
    rencontree en tableau est par definition non-evoluee. Nom affiche
    sous la zone (comme `%LabelNomJoueur` cote joueur).
  - `_terminer_tableau()` : si le tableau est reussi (>=7/10), appelle
    desormais `SaveManager.capturer_creature(_creature_sauvage_id)`
    pour de vrai (le flag `creature_capturee` distingue une premiere
    capture d'une recapture d'une creature deja au roster, pour ne pas
    afficher un message trompeur en cas de retente d'un niveau deja
    reussi). L'ecran de resultats affiche desormais une ligne
    "`<Nom>` a rejoint ton roster !" quand une nouvelle capture a eu
    lieu.
- **`scenes/EcranTableau.tscn`** : `ZoneSauvage` recoit la meme
  structure que `ZoneJoueur` (`%TextureSauvage`/`%PlaceholderSauvage`/
  `%LabelSauvage` pour le sprite, `%LabelNomSauvage` pour le nom en
  dessous) — remplace le placeholder fixe `"? (Phase 7)"` de la Phase 6.

## Bugs latents trouves et corriges (2e et 3e occurrence du meme piege)

Comme pour `capturer_creature()` trouve lors de l'ajout de la creature
principale, **`SaveManager.marquer_vue()` ne sauvegardait jamais non
plus** (meme cause : mutait `data` sans appeler `save_game()`). Cette
fonction n'avait jamais ete exercee en dehors de `new_game()` (qui
construit `creatures_vues` directement sans passer par elle) jusqu'a
cette phase — corrige de la meme facon, desormais couvert par un test
de persistance explicite.

**Lecon retenue (a appliquer proactivement a l'avenir)** : toute
methode de `SaveManager` qui mute `data` doit se terminer par
`save_game()`, meme si elle n'est pas encore appelee ailleurs dans le
code au moment ou elle est ecrite — l'absence d'appel reel masque
completement ce genre de bug jusqu'a ce qu'une phase future l'utilise
pour de vrai. Avant d'ajouter une nouvelle methode mutative a
`SaveManager`, verifier explicitement qu'elle appelle bien
`save_game()`.

## Verification effectuee

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (autoloads charges) : 0 erreur stderr.
- Nouveau `scripts/tests/smoke_test_phase7.gd` : `RencontreUtil`
  (aucun candidat, un seul candidat restant, reset si toutes vues),
  persistance de `marquer_vue()` (le bug ci-dessus), persistance de
  `get/definir_creature_rencontre()` (meme creature a chaque revisite),
  persistance de la capture reelle et detection "deja capturee",
  structure de `EcranTableau.tscn`. Suite complete des 12 smoke tests :
  tous SUCCES, aucune regression.
- Verification visuelle reelle complete : sauvegarde fraiche (starter
  seul), jeu lance sur le Hub, navigation reelle jusqu'a
  `pair_impair_niveau_01` -> capture confirmant qu'une creature
  sauvage (`Creature 3`, tiree parmi les non-vues) s'affiche a la place
  de l'ancien placeholder "? (Phase 7)". **10 clics reels** sur les
  bonnes reponses -> capture de l'ecran de resultats confirmant
  "Creature 3 a rejoint ton roster !" en plus du score/berries/XP
  habituels. Navigation reelle Continuer -> Hub -> Roster -> capture
  confirmant que **Creature 3 apparait bien desormais dans la liste**
  du Roster, capturee pour de vrai (persistee en sauvegarde).

## A faire en Phase 8 (polish et integration finale)

- Transitions fade in/out generalisees (le composant `TransitionRadiale`
  existe deja, utilise sur certains ecrans seulement).
- Remplacement des placeholders par les vrais assets si Mike les
  fournit d'ici la.
- Tests de bout en bout supplementaires si de nouveaux cas limites
  emergent en playtest reel avec l'enfant.
