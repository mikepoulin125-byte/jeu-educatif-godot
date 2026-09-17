extends Node
## Gere la sauvegarde de partie (fichier JSON dans user://).
## Voir section 10 de la spec pour le contenu exact.

const SAVE_PATH := "user://partie.save"

var data: Dictionary = {}

func _ready() -> void:
	if has_save():
		load_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Cree une nouvelle sauvegarde avec la creature de depart choisie.
func new_game(starter_id: String) -> void:
	data = {
		"starter_id": starter_id,
		"creatures_capturees": {
			starter_id: {"stage": 1, "xp_investi": 0}
		},
		"creatures_vues": [starter_id],
		"xp_total": 0,
		"progression": {}
	}
	save_game()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: impossible d'ecrire la sauvegarde")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		data = parsed
		return true
	push_error("SaveManager: sauvegarde corrompue")
	return false

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	data = {}

## --- XP ---

func add_xp(amount: int) -> void:
	data["xp_total"] = int(data.get("xp_total", 0)) + amount
	save_game()

func get_xp_total() -> int:
	return int(data.get("xp_total", 0))

## --- Creatures vues / capturees ---

func marquer_vue(creature_id: String) -> void:
	var vues: Array = data.get("creatures_vues", [])
	if not vues.has(creature_id):
		vues.append(creature_id)
		data["creatures_vues"] = vues

func get_creatures_vues() -> Array:
	return data.get("creatures_vues", [])

func capturer_creature(creature_id: String) -> void:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	if not capturees.has(creature_id):
		capturees[creature_id] = {"stage": 1, "xp_investi": 0}
	data["creatures_capturees"] = capturees

func get_creatures_capturees() -> Dictionary:
	return data.get("creatures_capturees", {})

## --- Progression par matiere ---

func get_progression_matiere(matiere_id: String) -> Dictionary:
	var progression: Dictionary = data.get("progression", {})
	return progression.get(matiere_id, {"niveaux": {}})

func set_progression_niveau(matiere_id: String, niveau_id: String, reussi: bool, score: int, debloque: bool = true) -> void:
	var progression: Dictionary = data.get("progression", {})
	if not progression.has(matiere_id):
		progression[matiere_id] = {"niveaux": {}}
	var niveaux: Dictionary = progression[matiere_id]["niveaux"]
	var precedent: Dictionary = niveaux.get(niveau_id, {})
	var meilleur_score: int = max(int(precedent.get("meilleur_score", 0)), score)
	niveaux[niveau_id] = {
		"debloque": debloque or bool(precedent.get("debloque", false)),
		"reussi": reussi or bool(precedent.get("reussi", false)),
		"meilleur_score": meilleur_score
	}
	progression[matiere_id]["niveaux"] = niveaux
	data["progression"] = progression
	save_game()

func est_niveau_debloque(matiere_id: String, niveau_id: String) -> bool:
	var prog := get_progression_matiere(matiere_id)
	var niveaux: Dictionary = prog.get("niveaux", {})
	return bool(niveaux.get(niveau_id, {}).get("debloque", false))
