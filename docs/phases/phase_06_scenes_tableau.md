# Phase 6 - Scenes de tableau

## Architecture

Plutot que 8 scenes de tableau completement independantes (duplication
massive de la logique commune : progression dans les questions, score,
XP, berries, resultats, deblocage), l'implementation separe :

- **`scenes/EcranTableau.tscn` + `scripts/ecran_tableau.gd`** :
  orchestrateur unique, commun aux 8 matieres. Charge le niveau
  (`DataManager.load_niveau("{matiere_id}_{niveau_id}")`), instancie le
  bon "widget de reponse" selon `GameState.matiere_courante_id`, pose
  les 10 questions une a une, gere XP/berries/feedback/resultats/
  deblocage du niveau suivant.
- **8 "widgets de reponse" reutilisables** (`scripts/tableau/*.gd` +
  `scenes/tableau/Widget*.tscn`, un par matiere), qui respectent un
  contrat commun minimal :
  ```
  func configurer(question: Dictionary, contexte: Dictionary) -> void
  signal reponse_donnee(correcte: bool)
  ```
  `contexte` ne sert qu'a `tableau_pictogramme` (transporte le
  `graphique` partage par les 10 questions du niveau). Chaque widget
  gere entierement l'affichage ET la saisie de sa question ; l'orchestrateur
  ne connait rien du detail de chaque mecanique.

Cette separation satisfait l'esprit de "8 scenes distinctes et
reutilisables, parametrees par les donnees JSON" (section 9 de la
spec) tout en evitant de dupliquer 8 fois la logique de score/XP/
berries/resultats.

## Simplifications assumees par rapport a la spec litterale

Deux mecaniques demandaient explicitement du glisser-depose dans la
spec d'origine ; simplifiees en interactions par clic pour rester
fiables a construire et a tester dans le temps imparti, sans perdre
l'objectif pedagogique :

- **`plan_cartesien`** : au lieu de glisser la creature sur une grille,
  l'enfant **clique directement la case (x,y)** demandee dans une
  grille de boutons (taille croissante avec le niveau, 5x5 a 10x10).
  Identifier/cliquer la bonne coordonnee reste le meme exercice
  pedagogique que la placer par glisser-depose.
- **`croissant_decroissant`** : au lieu de reordonner une suite par
  glisser-depose, l'enfant **regarde une suite deja affichee** et
  choisit "Croissant" ou "Decroissant" (c'est explicitement l'une des
  deux variantes proposees par la spec elle-meme, section 8 :
  "reordonner... OU choix multiple Croissant/Decroissant selon la
  question" — la variante choix multiple est retenue partout ici).

Le systeme de glisser-depose existe deja dans le projet (berries sur
Roster, Phase 4 bis) : si Mike souhaite un vrai drag-and-drop pour ces
deux mecaniques plus tard, l'infrastructure (`_get_drag_data`/
`_can_drop_data`/`_drop_data`) est un patron connu, pas une inconnue
technique — juste hors scope pour cette passe.

Le combat "joueur vs creature sauvage" de la spec (section 9) est
**visuel seulement** pour l'instant : sprite du starter du joueur a
gauche, placeholder generique "? (Phase 7)" a droite (la logique de
rencontre/capture qui determinerait la VRAIE creature sauvage n'existe
pas encore, c'est la Phase 7).

## Contenu des 80 niveaux

Les 79 fichiers de niveaux restants (`pair_impair_niveau_01.json` avait
deja son contenu depuis la Phase 5) ont ete remplis avec de vraies
questions scriptees, **generees via un script bash d'auteur**
(`gen_*` dans un script jetable, non versionne) pour produire un volume
coherent (800 questions) sans les ecrire une par une a la main — le
resultat ecrit dans les fichiers JSON est fige, aucune generation n'a
lieu au moment de jouer (respecte "questions scriptees a la main, pas
de generation aleatoire" de la spec, qui concerne le comportement EN
JEU, pas le processus d'ecriture des fichiers).

Regles de progression de difficulte (niveau 1 = facile -> niveau 10 =
difficile), calibrees pour rester dans l'esprit 2e annee Quebec
(nombres jusqu'a ~100, fractions simples 1/2 a 1/8, additions/
soustractions) :

| Matiere | Progression |
|---|---|
| pair_impair | plage de nombres 1-10 -> 1-100 |
| terme_manquant | operandes 5-10 -> 5-60 |
| approximation | tolerance d'estimation 6 -> 2 (plus serree = plus dur) |
| plan_cartesien | grille 5x5 -> 10x10 |
| possible_impossible | flaveur de niveau croissante (logique de types identique, 3 types dans `types.json`) |
| tableau_pictogramme | 3 -> 5 categories dans le graphique |
| fractions | 1/2-1/4 -> ajoute 1/5, 1/6, 1/8 a partir du niveau 5 |
| croissant_decroissant | suite de 4 -> 6 nombres |

Schema JSON par matiere (champ `"questions"`, 10 entrees) :
- `pair_impair` : `{"nombre": N, "reponse": "pair"|"impair"}`
- `approximation` : `{"texte": "...", "min": N, "max": N}`
- `terme_manquant` : `{"texte": "a + ? = b", "reponse": N}`
- `plan_cartesien` : `{"x": N, "y": N, "taille_grille": N}`
- `possible_impossible` : `{"texte": "...", "reponse": "possible"|"impossible"}`
- `tableau_pictogramme` : `{"texte": "...", "reponse": N}` + un champ
  **au niveau du fichier** (pas par question) `"graphique": {"titre":
  "...", "barres": [{"categorie": "...", "valeur": N}, ...]}`, partage
  par les 10 questions.
- `fractions` : `{"texte": "...", "choix": ["1/2","1/3","1/4"], "reponse_index": N}`
- `croissant_decroissant` : `{"suite": [N, N, ...], "reponse": "croissant"|"decroissant"}`

Qualite du contenu genere : fonctionnel et curriculum-coherent, mais
avec un peu de repetition (periode de quelques questions pour
`tableau_pictogramme`/`fractions` du fait de la formule de generation).
Mike peut librement editer ces fichiers JSON a la main pour varier
davantage — ce sont de simples fichiers de donnees, la mecanique de
jeu ne change pas.

## XP, berries, resultats (branchement reel)

- **+10 XP par bonne reponse**, **+50 XP bonus si score >= 8/10** :
  `SaveManager.add_xp()`, appele dans `ecran_tableau.gd`.
- **+1 berry par bonne reponse (jusqu'a 10/tableau), skin aleatoire** :
  `SaveManager.ajouter_berry()` (deja construit en Phase 4 bis, juste
  branche ici pour de vrai).
- **Bouton de debug retire** : `%BoutonDebugBerry` supprime de
  `Roster.tscn`/`roster.gd` (et de `smoke_test_phase4.gd`) maintenant
  que la vraie distribution existe.
- Fin de tableau : `SaveManager.set_progression_niveau()` +
  deblocage du niveau suivant si reussi — logique identique a celle
  qui existait dans `EcranTableauPlaceholder.gd` (Phase 5), **deplacee**
  dans `ecran_tableau.gd` (le placeholder est supprime, plus besoin).
- Ecran de resultats (panneau superpose, pas une scene separee, pour
  eviter de re-passer l'etat score/berries/XP par `GameState`) :
  score/10, berries gagnees, XP gagne (detail du bonus si applicable),
  message reussi/echoue, bouton "Continuer" -> `SelectionNiveau.tscn`.

## Bugs trouves et corriges

- **Meme piege `@onready`/timing que Phase 3, sur les 8 widgets** :
  `ecran_tableau.gd` instancie un widget puis appelle `configurer()`
  immediatement (`add_child()` suivi d'un appel synchrone), exactement
  le scenario qui casse les `@onready var x = %Nom` (voir Phase 3). Les
  8 widgets ont ete ecrits avec ce cache en premier jet, **trouve par
  le smoke test** (`ECHEC: pair_impair : 'pair' sur 4 devrait etre
  correct`, cause reelle : `Invalid assignment ... on a base object of
  type 'Nil'`). Corrige partout : resolution de `%Nom` a la demande
  dans `configurer()`/les handlers, jamais en cache `@onready` pour les
  noeuds touches par `configurer()`.
- **Affichage `4.0` au lieu de `4`** : trouve uniquement par la
  **verification visuelle reelle** (pas par le smoke test, qui
  construisait ses questions de test directement en GDScript avec des
  `int` litteraux plutot que via un vrai chargement JSON). Cause :
  apres un chargement JSON, un nombre entier revient en `float`
  (`4.0`), et `str(4.0)` donne `"4.0"`. Deux widgets affichaient un
  nombre JSON sans le passer par `int(...)` d'abord :
  `widget_pair_impair.gd` (le nombre a classer) et
  `widget_croissant_decroissant.gd` (les elements de la suite). Meme
  famille de piege que le round-trip JSON deja documente en Phase 4 bis
  (berries), mais cette fois sur un **affichage** plutot qu'une
  **comparaison** — a surveiller pour tout futur widget qui affiche un
  nombre issu directement d'un fichier JSON.

## Verification effectuee

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (autoloads charges) : 0 erreur stderr.
- Validation Node.js independante des 80 fichiers JSON generes (parse +
  10 questions chacun) avant meme de lancer Godot.
- Suite complete des smoke tests (10 fichiers, dont le nouveau
  `smoke_test_phase6.gd`) : tous SUCCES, aucune regression.
  `smoke_test_phase6.gd` valide le schema des 80 fichiers de niveaux,
  et teste chacun des 8 widgets individuellement (bonne ET mauvaise
  reponse, construction de la grille `plan_cartesien`, construction du
  graphique `tableau_pictogramme`) en les pilotant directement (ces
  widgets, contrairement a `ecran_tableau.gd`, ne referencent aucun
  autoload et compilent/s'executent normalement sous `--script`).
- **Verification visuelle reelle : une partie complete jouee du debut
  a la fin avec des clics reels simules**, pas de raccourci : jeu
  lance sur le Hub, clic reel sur le badge "Pair / impair", clic reel
  sur "Niveau 1", puis **10 clics reels** sur "Pair"/"Impair" en
  suivant exactement les 10 bonnes reponses de
  `pair_impair_niveau_01.json` (verifie le premier chargement JSON reel
  d'une question, ce qui a revele le bug `4.0` ci-dessus — corrige puis
  la partie entiere rejouee depuis le debut). Capture des resultats
  confirmant : **Score 10/10, Berries gagnees 10, XP gagne 150 (dont 50
  de bonus)**. Clic reel sur "Continuer" -> capture confirmant le
  retour a `SelectionNiveau` avec niveau 1 en vert ("Meilleur score :
  10/10") et niveau 2 debloque. Navigation reelle Hub -> Roster ->
  capture confirmant les **10 berries** (skins varies) presentes dans
  l'inventaire et le bouton de debug bien absent.

## A faire en Phase 7 (rencontre/capture)

- Remplacer le placeholder "`? (Phase 7)`" de `ZoneSauvage` dans
  `EcranTableau.tscn` par la vraie creature sauvage tiree au hasard
  parmi les non-evoluees jamais vues (section 9.1 de la spec).
- Integrer la capture (reussite du tableau >= 7/10) avec
  `SaveManager.capturer_creature()` (existe depuis la Phase 1) et
  `SaveManager.marquer_vue()`.

## Ajout : "creature principale" (demande pendant la Phase 6)

Mike a demande, pendant la construction de l'ecran de tableau, un
systeme de creature "principale"/active choisie par le joueur depuis le
Roster, qui est celle affichee cote joueur dans les tableaux — integre
nativement plutot qu'en retrofit puisque `EcranTableau.tscn` etait deja
en chantier.

- **`SaveManager`** : `data["creature_principale_id"]`.
  `get_creature_principale_id()` / `definir_creature_principale(id)`.
  **Decision documentee sur le repli par defaut** (aucun choix explicite
  n'a encore ete fait) : le starter, sinon la premiere creature
  capturee (ordre du dictionnaire de sauvegarde) — garantit qu'une
  creature principale existe toujours des qu'au moins une creature est
  capturee (le starter l'est toujours des la creation de la partie).
  `definir_creature_principale()` refuse silencieusement une creature
  non capturee (pas de crash, pas d'etat invalide).
- **Roster** (`scenes/Roster.tscn` + `scripts/roster.gd`) : nouveau
  bouton `%BoutonPrincipale` ("Accompagne-moi !") dans le panneau de
  details, sous "Stade X/Y". Se desactive et affiche "Creature
  principale actuelle" quand la creature selectionnee est deja la
  principale. Badge "★" (`%LabelBadgePrincipale` sur
  `CarteCreatureRoster`, `definir_principale(bool)`) affiche sur la
  carte de la creature principale dans la liste, mis a jour a chaque
  changement (`_actualiser_badges_principale()`).
- **`EcranTableau`** (`scripts/ecran_tableau.gd::_afficher_creature_joueur()`) :
  affiche desormais `SaveManager.get_creature_principale_id()` (sprite
  au stade actuel, avec sprite "glow" si debloque comme au Roster) au
  lieu du starter fixe. Nouveau `%LabelNomJoueur` sous la zone du
  joueur affiche son nom (surnom si defini, sinon nom d'espece) — reste
  la meme creature tant que le joueur n'en choisit pas une autre depuis
  le Roster (persiste en sauvegarde, pas dans `GameState`).

### Bug trouve (par la verification visuelle, pas par les smoke tests)

`SaveManager.capturer_creature()` **ne sauvegardait jamais** —
mutait `data` en memoire sans appeler `save_game()`, contrairement a
toutes les autres methodes mutatives du fichier. Cree en Phase 1,
jamais exerce en dehors du chemin `new_game()` (qui construit le
dictionnaire directement sans passer par cette fonction) jusqu'a ce que
la verification visuelle de cette fonctionnalite l'utilise pour de
vrai (capturer une 2e creature pour tester le choix entre plusieurs
principales) — la 2e creature disparaissait silencieusement au
redemarrage. Corrige (`save_game()` ajoute), et desormais couvert par
un test de non-regression explicite. **Important pour la Phase 7** :
cette fonction sera abondamment utilisee pour la vraie capture, le bug
aurait ete bien plus difficile a diagnostiquer une fois noye dans la
logique de rencontre.

### Verification effectuee (creature principale)

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (autoloads charges) : 0 erreur stderr.
- Nouveau `scripts/tests/smoke_test_creature_principale.gd` : repli par
  defaut sur le starter, changement de creature principale, refus
  silencieux pour une creature non capturee, persistance apres reload,
  repli propre si la principale enregistree n'est plus valide, bascule
  du badge sur `CarteCreatureRoster`, structure des deux scenes — plus
  la verification explicite que `capturer_creature()` persiste bien
  (le bug ci-dessus). Suite complete des 11 smoke tests : tous SUCCES,
  aucune regression.
- Verification visuelle reelle complete : sauvegarde de test avec 2
  creatures capturees (starter + une seconde via `capturer_creature()`,
  ce qui a revele le bug de sauvegarde manquante ci-dessus — corrige
  puis la sauvegarde regeneree). Jeu lance en fenetre : capture du
  Roster confirmant le badge ★ sur le starter par defaut, **clic reel**
  sur la 2e creature puis sur "Accompagne-moi !" -> capture confirmant
  le badge deplace, le message "Elle t'accompagnera dans les
  tableaux !" et le bouton desactive. Navigation reelle Hub -> matiere
  -> niveau 1 -> capture confirmant que **la 2e creature (pas le
  starter) s'affiche bien cote joueur**, avec son nom sous "Toi".
