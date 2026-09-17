# Phase 1 - Fondations

## Fichiers crees

- `project.godot` : resolution 1920x1080, stretch mode canvas_items/keep,
  autoloads `DataManager`, `SaveManager`, `GameState`.
- `scripts/autoload/data_manager.gd` : charge `data/creatures.json`,
  `data/matieres.json`, `data/types.json` au demarrage (`reload_all()`), et
  les fichiers de `data/niveaux/*.json` a la demande (`load_niveau(id)`).
  Parsing JSON defensif : fichier manquant ou JSON invalide -> warning +
  valeur vide, jamais de crash.
- `scripts/autoload/save_manager.gd` : sauvegarde JSON dans
  `user://partie.save`. Schema (voir section 10 de la spec) :
  ```
  {
    "starter_id": "...",
    "creatures_capturees": { "<id>": {"stage": 1, "xp_investi": 0} },
    "creatures_vues": ["<id>", ...],
    "xp_total": 0,
    "progression": { "<matiere_id>": { "niveaux": { "<niveau_id>": {"debloque":..,"reussi":..,"meilleur_score":..} } } }
  }
  ```
  API : `has_save`, `new_game`, `save_game`, `load_game`, `delete_save`,
  `add_xp`, `get_xp_total`, `marquer_vue`, `get_creatures_vues`,
  `capturer_creature`, `get_creatures_capturees`,
  `get_progression_matiere`, `set_progression_niveau`,
  `est_niveau_debloque`.
- `scripts/autoload/game_state.gd` : etat de session transitoire (matiere/
  niveau courant), pas sauvegarde sur disque.
- `scenes/Main.tscn` + `scripts/main.gd` : point d'entree, redirige vers
  `MenuPrincipal.tscn`.
- `scenes/MenuPrincipal.tscn` + `scripts/menu_principal.gd` : ecran titre
  (Nouvelle partie / Continuer / Quitter). "Continuer" desactive si
  `SaveManager.has_save()` est faux.
- `scenes/DebugEtatSauvegarde.tscn` : ecran temporaire affichant l'etat de
  la sauvegarde + des donnees chargees. Reste utile comme destination
  provisoire tant que le hub (Phase 3) n'existe pas.
- `data/creatures.json`, `data/matieres.json`, `data/types.json` :
  placeholders avec quelques entrees d'exemple.
- Dossiers `assets/creatures/`, `assets/backgrounds/`, `assets/ui/`,
  `data/niveaux/` crees (vides, `.gitkeep`).

## Particularites techniques a retenir

- **Godot 4.6 + `func _read_json()` : ne jamais utiliser `:=` sur le
  retour de `JSON.parse_string()`** (type `Variant`) — ce projet a les
  avertissements de type traites comme erreurs, `var x := ...` sur une
  valeur Variant fait planter le chargement du script. Utiliser `var x =
  ...` (sans `:=`) a la place.
- **`get_tree().change_scene_to_file()` appele depuis `_ready()` du noeud
  racine doit etre differe** (`.call_deferred(...)`), sinon erreur
  "Parent node is busy adding/removing children" au boot.
- Verification faite via `godot --headless --path <projet> --import` (0
  erreur) et une execution headless de quelques secondes (0 erreur
  stderr).

## Godot installe sur la machine

Installe via `winget install --id GodotEngine.GodotEngine --version 4.6.3`.
Executable : `%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe` (l'alias
`godot` necessite un nouveau terminal / redemarrage de session pour etre
sur le PATH, winget n'a pas pu creer le lien symbolique sans privileges
admin).
