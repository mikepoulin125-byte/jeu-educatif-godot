# Phase 3 - Hub principal

## Fichiers crees

- `scripts/util/ui_icon_util.gd` (`class_name UiIconUtil`) : meme
  principe que `SpriteUtil` (Phase 2), mais pour `assets/ui/*.png`.
  Resout un id d'icone vers son fichier s'il existe, sinon `null`.
- `scenes/components/CarteMatiere.tscn` + `scripts/components/carte_matiere.gd` :
  badge/bouton reutilisable pour une matiere (icone reelle ou
  placeholder + nom + description). La racine est elle-meme un
  `Button` (texte vide), toute la carte est cliquable. Emet
  `choisie(matiere_id)`.
- `scenes/Hub.tscn` + `scripts/hub.gd` : le hub principal (section 6 de
  la spec). Affiche `SaveManager.get_xp_total()` en haut-gauche, un
  bouton Roster permanent en haut-droite, et une grille 4x8 (colonnes)
  de `CarteMatiere` generee dynamiquement depuis `DataManager.matieres`
  (donc directement pilotee par `data/matieres.json`, aucune matiere en
  dur).
- `scenes/SelectionNiveau.tscn` + `scripts/selection_niveau_placeholder.gd` :
  **placeholder Phase 5**. Confirme juste que le clic sur un badge
  fonctionne (affiche le nom de la matiere choisie via
  `GameState.matiere_courante_id`) et permet de revenir au hub.
- `scenes/Roster.tscn` + `scripts/roster_placeholder.gd` : **placeholder
  Phase 4**. Confirme que le bouton Roster du hub fonctionne, permet de
  revenir au hub.
- `scripts/tests/smoke_test_phase3.gd` : verifie que les 8 matieres se
  chargent avec les bons ids, que chaque `CarteMatiere` s'applique
  correctement (egalite stricte du nom affiche, pas juste "non vide"),
  et que `SaveManager.add_xp()` met a jour le total correctement.

## Navigation mise a jour

- `menu_principal.gd` ("Continuer") et `selection_starter.gd` (apres
  choix du starter) menent maintenant vers `Hub.tscn` (au lieu du
  placeholder `DebugEtatSauvegarde.tscn` de la Phase 1/2, qui reste
  dans le repo comme outil de debug mais n'est plus reference par le
  flux normal).
- Hub -> clic sur une matiere -> `SelectionNiveau.tscn` (placeholder).
- Hub -> bouton Roster -> `Roster.tscn` (placeholder).
- Les transitions fade in/out prevues par la spec (section 8) sont
  **volontairement differees a la Phase 8** ("Polish et integration
  finale"), qui est explicitement dediee aux transitions dans le
  decoupage en 8 phases (section 12 de la spec). Pour l'instant, les
  changements de scene sont instantanes.

## Bug important trouve et corrige (affecte aussi la Phase 2)

**`@onready var x = %NodeName` ne se peuple qu'au moment ou `_ready()`
se declenche, et `_ready()` n'est PAS forcement synchrone apres
`add_child()`.** Dans un script `SceneTree` lance via
`godot --headless --script ...` (utilise par tous les smoke tests de ce
projet), il n'y a pas de boucle de frame avant `quit()` : un noeud
ajoute dynamiquement (`instantiate()` + `add_child()` + configuration
immediate) peut ne jamais recevoir son `_ready()` avant la fin du
script. Le test Phase 3 (avec verification stricte du texte, contrairement
au test Phase 2 initial qui verifiait seulement "non vide" — un faux
positif silencieux) a mis ce bug en evidence : `CarteMatiere.configurer()`
mettait les donnees "en attente" pour `_ready()`, mais `_ready()` n'arrivait
jamais dans ce contexte, donc le texte restait au placeholder par defaut du
`.tscn` ("Nom"/"Description").

**Correctif applique a `CarteCreature` et `CarteMatiere`** : abandon du
cache `@onready` + mecanisme "en attente" pour resoudre les noeuds
enfants (`%NodeName`) directement dans `configurer()`/`_appliquer()`,
a chaque appel. La resolution `%NodeName` fonctionne des
`instantiate()` (elle depend de `owner`, deja assigne a
l'instanciation, pas de `_ready()`). Le bouton "pressed" est connecte
de facon idempotente (flag `_pressed_connecte`) a la fois depuis
`_ready()` (cas normal du jeu) et depuis `configurer()` (au cas ou
configurer() est appele avant que le noeud n'entre dans l'arbre).

**Reflexe a appliquer pour tout futur composant reutilisable** :
preferer la resolution `%NodeName` a la demande plutot que le cache
`@onready`, des qu'un composant peut etre configure immediatement apres
`instantiate()` (avant ou juste apres `add_child()`). Le smoke test
Phase 2 a aussi ete durci (egalite stricte du nom, plus "non vide") pour
eviter de refaire ce genre de faux positif a l'avenir.

**Autre piege decouvert : `assert()` dans un script headless peut
bloquer indefiniment.** Un `assert()` qui echoue declenche une pause du
debugger de script GDScript ; sans debugger attache (cas normal d'un
`godot --headless --script ...` lance depuis un terminal), le processus
reste bloque au lieu de planter proprement. Les deux smoke tests
utilisent maintenant une fonction `_verifier(condition, message)` qui
imprime l'echec et appelle `quit(1)` explicitement — **ne plus jamais
utiliser `assert()` dans un script de test headless de ce projet.**

## Verification effectuee

- `godot --headless --path <projet> --import` : 0 erreur.
- Execution headless du boot (Main -> MenuPrincipal) : 0 erreur stderr.
- `scripts/tests/smoke_test_phase2.gd` (durci) : SUCCES.
- `scripts/tests/smoke_test_phase3.gd` : SUCCES.
