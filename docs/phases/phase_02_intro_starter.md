# Phase 2 - Intro et starter

## Fichiers crees

- `data/intro.json` : lignes de l'intro narrative (`{"lignes": [...]}`),
  editable librement par Mike. Charge via `DataManager.get_lignes_intro()`.
- `data/creatures.json` : ajout du champ `"starter": true` sur les
  creatures proposees a l'ecran de choix de depart. Les 3 entrees
  placeholder existantes sont toutes marquees starter (pour pouvoir
  tester l'ecran a 3 cartes). Nouvelle API `DataManager.get_creatures_starters()`.
- `scripts/util/sprite_util.gd` (`class_name SpriteUtil`) : resout un id
  de sprite (`"c1"`) vers `assets/creatures/c1.png` s'il existe deja,
  sinon retourne `null` (le composant appelant doit alors afficher un
  placeholder). Utilitaire partage, sera reutilise partout ou une
  creature doit s'afficher (Roster, tableaux, etc.).
- `scenes/components/CarteCreature.tscn` + `scripts/components/carte_creature.gd` :
  composant reutilisable (sprite ou placeholder + nom + description +
  bouton "Choisir"), emet le signal `choisie(creature_id)`. Utilise pour
  l'ecran de starter, sera probablement reutilise pour le Roster (Phase 4).
- `scenes/DialogueIntro.tscn` + `scripts/dialogue_intro.gd` : boite de
  dialogue avec revelation progressive du texte (effet machine a
  ecrire), clic/Espace/Entree pour completer la ligne ou avancer.
  Enchaine automatiquement vers `SelectionStarter.tscn` a la derniere
  ligne (ou immediatement si `data/intro.json` est vide).
- `scenes/SelectionStarter.tscn` + `scripts/selection_starter.gd` :
  instancie une `CarteCreature` par creature marquee `starter` dans
  `creatures.json`, dans un `HBoxContainer` centre. Au clic sur une
  carte : `SaveManager.new_game(creature_id)` puis redirection (voir
  "etat provisoire" ci-dessous).
- `scripts/menu_principal.gd` : "Nouvelle partie" redirige maintenant
  vers `DialogueIntro.tscn` (au lieu de creer directement une
  sauvegarde vide).
- `scripts/tests/smoke_test_phase2.gd` : script de test headless
  (`godot --headless --script res://scripts/tests/smoke_test_phase2.gd`),
  pas execute en jeu normal. Verifie : chargement de `intro.json`,
  detection des starters, configuration des `CarteCreature` sans
  crash, creation + persistance de la sauvegarde via `SaveManager`.
  A relancer apres toute modification touchant ce flux.

## Etat provisoire (a corriger en Phase 3)

Le hub principal n'existe pas encore : le choix d'un starter redirige
vers `scenes/DebugEtatSauvegarde.tscn` (comme "Continuer" au menu
titre). A remplacer par la vraie navigation vers le hub des 8 matieres
en Phase 3 (chercher `DebugEtatSauvegarde` dans `selection_starter.gd`
et `menu_principal.gd`).

## Particularites techniques a retenir

- **Piege `@onready` + composant instancie dynamiquement** : si on fait
  `var n = Scene.instantiate(); parent.add_child(n); n.configurer(...)`
  dans la meme fonction, `configurer()` peut s'executer *avant* que
  `_ready()` (et donc les `@onready var x = %Y`) du noeud instancie ne
  soit passe -> erreur "Invalid assignment... on a base object of type
  Nil". Trouve par le smoke test, corrige dans `carte_creature.gd` en
  mettant la donnee en attente si `not is_node_ready()`, appliquee dans
  `_ready()` sinon. **Reflexe a appliquer a tout futur composant
  reutilisable configure juste apres `add_child()`.**
- **`godot --headless --script <path>` ne charge PAS les autoloads**
  (erreur de compilation "Identifier not found: DataManager"). Pour un
  script de test headless, instancier les scripts d'autoload
  manuellement (`preload(...).new()`) plutot que de referencer le nom
  global de l'autoload.
- Effet machine a ecrire : geree par `_process(delta)` avec un compteur
  de caracteres flottant (`VITESSE_CARACTERES_PAR_SEC`), pas de Timer —
  plus simple a interrompre/completer instantanement au clic.
- Entree clavier/souris de la boite de dialogue geree via
  `_unhandled_input()` (pas `_gui_input`) pour eviter les soucis de
  focus clavier sur un `Control` qui n'a pas le focus par defaut.

## Verification effectuee

- `godot --headless --path <projet> --import` : 0 erreur.
- Execution headless du boot (Main -> MenuPrincipal) : 0 erreur stderr.
- `scripts/tests/smoke_test_phase2.gd` : SUCCES (exit code 0, 0 warning
  restant apres nettoyage des objets crees manuellement dans le test).
