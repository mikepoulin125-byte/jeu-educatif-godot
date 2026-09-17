extends Node
## Charge et expose les données statiques du jeu (data/*.json).
## Aucun contenu (noms, textes, stats) n'est en dur ici : tout vient des fichiers JSON.

const DATA_DIR := "res://data/"
const NIVEAUX_DIR := "res://data/niveaux/"

var creatures: Dictionary = {}   # id -> Dictionary
var matieres: Array = []         # liste des 8 badges, dans l'ordre du fichier
var types: Dictionary = {}       # table des types elementaires

func _ready() -> void:
	reload_all()

func reload_all() -> void:
	creatures = _load_creatures()
	matieres = _load_json_array(DATA_DIR + "matieres.json", "matieres")
	types = _load_json_dict(DATA_DIR + "types.json")

func _load_creatures() -> Dictionary:
	var arr := _load_json_array(DATA_DIR + "creatures.json", "creatures")
	var by_id := {}
	for entry in arr:
		if entry is Dictionary and entry.has("id"):
			by_id[entry["id"]] = entry
	return by_id

func _load_json_array(path: String, key: String) -> Array:
	var parsed = _read_json(path)
	if parsed is Dictionary and parsed.has(key) and parsed[key] is Array:
		return parsed[key]
	if parsed is Array:
		return parsed
	push_warning("DataManager: impossible de charger '%s' (cle '%s')" % [path, key])
	return []

func _load_json_dict(path: String) -> Dictionary:
	var parsed = _read_json(path)
	if parsed is Dictionary:
		return parsed
	push_warning("DataManager: impossible de charger '%s'" % path)
	return {}

func _read_json(path: String):
	if not FileAccess.file_exists(path):
		push_warning("DataManager: fichier introuvable: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("DataManager: erreur d'ouverture: %s" % path)
		return null
	var text := file.get_as_text()
	var result = JSON.parse_string(text)
	if result == null:
		push_warning("DataManager: JSON invalide: %s" % path)
	return result

## Retourne les lignes de l'intro narrative (data/intro.json).
func get_lignes_intro() -> Array:
	return _load_json_array(DATA_DIR + "intro.json", "lignes")

## Retourne les creatures marquees "starter": true dans creatures.json.
func get_creatures_starters() -> Array:
	var ids := []
	for id in creatures.keys():
		if bool(creatures[id].get("starter", false)):
			ids.append(id)
	return ids

## Charge un fichier de niveau, ex. "matiere_01_niveau_01".
func load_niveau(niveau_id: String) -> Dictionary:
	var path := NIVEAUX_DIR + niveau_id + ".json"
	var parsed = _read_json(path)
	if parsed is Dictionary:
		return parsed
	return {}

## Retourne la liste des IDs de creatures non evoluees (stage 1 uniquement, base de la ligne).
func get_creatures_non_evoluees() -> Array:
	var ids := []
	for id in creatures.keys():
		ids.append(id)
	return ids

func get_matiere_by_id(matiere_id: String) -> Dictionary:
	for m in matieres:
		if m is Dictionary and m.get("id") == matiere_id:
			return m
	return {}
