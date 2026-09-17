# Phase 5 - Selection de niveau

## Fichiers crees / modifies

- `data/niveaux/*.json` (80 fichiers, un par matiere x niveau) :
  `{matiere_id}_niveau_{NN}.json`. Chacun a au minimum `{"nom": "..."}`.
  Noms thematiques originaux definis par Claude (8 themes, un par
  matiere, aucune reference a une franchise existante) :
  - pair_impair -> "Sentier Pair-Impair"
  - approximation -> "Vallee des Estimations"
  - terme_manquant -> "Grotte du Chiffre Cache"
  - plan_cartesien -> "Plateau des Coordonnees"
  - possible_impossible -> "Foret du Possible"
  - tableau_pictogramme -> "Rivage des Pictogrammes"
  - fractions -> "Verger des Fractions"
  - croissant_decroissant -> "Colline Croissante"

  Chaque niveau = "{theme} {numero}" (ex. "Sentier Pair-Impair 3").
  **Un seul exemple complet** avec ses 10 questions scriptees :
  `pair_impair_niveau_01.json` (schema de reference pour la Phase 6 :
  `{"nombre": N, "reponse": "pair"|"impair"}`). Les 79 autres fichiers
  ont `"questions": []` — a remplir progressivement en Phase 6, au fur
  et a mesure que chaque mecanique d'interaction est construite.
- `scenes/components/CarteNiveau.tscn` + `scripts/components/carte_niveau.gd` :
  bouton de niveau a 3 etats. "verrouille" utilise simplement
  `disabled = true` avec le style "disabled" du theme (Godot ignore deja
  normal/hover/pressed pour un bouton desactive, donc rien d'autre a
  faire) ; "reussi" bascule normal/hover/pressed vers une variante verte
  partagee (`@export StyleBoxFlat`, pas de duplication necessaire car
  jamais mutee par instance, contrairement au placeholder colore de
  `CarteMatiere`).
- `scenes/SelectionNiveau.tscn` + `scripts/selection_niveau.gd`
  (remplace le placeholder de Phase 3, supprime) : grille de 10
  `CarteNiveau` pour `GameState.matiere_courante_id`. **Le niveau 1 est
  toujours considere debloque** (verite codee en dur dans
  `_peupler_niveaux()`, `numero == 1 or ...` — jamais lu depuis la
  sauvegarde, contrairement aux niveaux 2-10 qui dependent de
  `SaveManager.est_niveau_debloque()`). Meme famille visuelle que le Hub
  (fond a bandes diagonales, XP permanent, bouton retour). Fondu
  d'entree (`TransitionRadiale`) present ici car **explicitement demande
  par la spec d'origine** (section 8 : "fade out du menu actuel, fade in
  sur l'ecran de selection de niveau"), contrairement au Roster qui ne
  l'a pas (pas demande pour cette transition-la).
- `scenes/EcranTableauPlaceholder.tscn` + `scripts/ecran_tableau_placeholder.gd` :
  **placeholder Phase 6** (les 8 vraies mecaniques de tableau n'existent
  pas encore). Affiche le nom de la matiere/niveau, et fournit 2
  boutons de debug qui simulent la fin d'un tableau :
  - "[DEBUG] Reussir (8/10)" -> `SaveManager.set_progression_niveau(matiere_id, niveau_id, true, 8, true)`
    PUIS debloque explicitement le niveau suivant (`set_progression_niveau`
    sur `niveau_id + 1` avec `debloque=true`, `reussi=false`).
  - "[DEBUG] Echouer (4/10)" -> meme appel avec `reussi=false, score=4`,
    ne debloque rien de plus.
  - Cette logique (marquer reussi/echoue + debloquer le niveau suivant
    seulement si reussi) est exactement ce que chaque vraie scene de
    tableau de la Phase 6 devra reproduire a la fin de ses 10 questions
    — le placeholder sert donc aussi de reference d'implementation.
- `scripts/tests/smoke_test_phase5.gd` : verifie les 80 fichiers de
  niveaux (nom present), l'exemple complet (10 questions), le
  deblocage sequentiel (niveau 1 toujours debloque, reussite deverrouille
  le suivant et seulement le suivant, echec ne deverrouille rien de
  plus), la persistance apres reload, les 3 etats de `CarteNiveau`, et
  la structure des deux nouvelles scenes.

## Verification effectuee

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (autoloads charges) : 0 erreur stderr.
- Suite complete des smoke tests (9 fichiers) : tous SUCCES, aucune
  regression.
- Verification visuelle reelle complete, flux entier en conditions
  reelles (pas de bascule artificielle de `main_scene` sur l'ecran
  cible cette fois — lance sur `Hub.tscn`, navigation par vrais clics) :
  1. Sauvegarde fraiche generee, jeu lance sur le Hub, **clic reel** sur
     le badge "Pair / impair" -> capture de `SelectionNiveau` : niveau 1
     disponible (bordure rouge), niveaux 2-10 grises avec
     "(verrouille)", noms thematiques corrects.
  2. **Clic reel** sur "Niveau 1" -> capture de l'ecran de tableau
     placeholder, nom de la matiere/niveau corrects.
  3. **Clic reel** sur "[DEBUG] Reussir (8/10)" -> message "Reussi !
     (8/10) - niveau suivant debloque." affiche.
  4. **Clic reel** sur "Retour a la selection de niveau" -> capture
     confirmant : niveau 1 en vert avec "Meilleur score : 8/10", niveau
     2 desormais disponible (bordure rouge, cliquable), niveaux 3-10
     toujours verrouilles.

## A faire en Phase 6

- Remplacer `EcranTableauPlaceholder.tscn` par les 8 vraies scenes de
  mecanique d'interaction (section 9 de la spec), en reprenant la
  logique de fin de tableau documentee ci-dessus.
- Remplir les `"questions": []` des 79 fichiers de niveaux restants au
  fur et a mesure (10 questions scriptees par niveau, pas de
  generation aleatoire — voir section 8/9 de la spec).
- Brancher la distribution reelle de berries (1 par bonne reponse, voir
  Phase 4 bis) a la fin de chaque question reussie.
