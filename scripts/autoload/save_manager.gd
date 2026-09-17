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
			starter_id: _nouvelle_entree_creature()
		},
		"creatures_vues": [starter_id],
		"xp_total": 0,
		"progression": {},
		"berries_inventaire": []
	}
	save_game()

func _nouvelle_entree_creature() -> Dictionary:
	return {"stage": 1, "xp_investi": 0, "surnom": "", "berries_recues": 0}

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
		capturees[creature_id] = _nouvelle_entree_creature()
	data["creatures_capturees"] = capturees

func get_creatures_capturees() -> Dictionary:
	return data.get("creatures_capturees", {})

func get_stage_creature(creature_id: String) -> int:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	return int(capturees.get(creature_id, {}).get("stage", 1))

func get_xp_investi_creature(creature_id: String) -> int:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	return int(capturees.get(creature_id, {}).get("xp_investi", 0))

## --- Evolution (section 7 de la spec) ---
## Cout fixe : 300 XP pour atteindre le stade 2, 500 XP pour le stade 3.
## Le stade maximal d'une creature (champ "stages" de creatures.json)
## n'est PAS connu de SaveManager (separation des responsabilites :
## SaveManager gere la persistance, DataManager le contenu) — c'est a
## l'appelant (l'ecran Roster) de ne pas proposer d'evolution au-dela du
## stade maximal avant d'appeler faire_evoluer_creature().

const COUT_EVOLUTION_STAGE_2 := 300
const COUT_EVOLUTION_STAGE_3 := 500

## Cout pour atteindre "stage_cible" (2 ou 3) depuis le stade precedent.
## Retourne -1 pour toute autre valeur (pas de cout defini).
func cout_evolution_vers(stage_cible: int) -> int:
	match stage_cible:
		2:
			return COUT_EVOLUTION_STAGE_2
		3:
			return COUT_EVOLUTION_STAGE_3
		_:
			return -1

## Fait passer la creature au stade suivant si le joueur a assez de XP.
## Retourne true si l'evolution a eu lieu (et sauvegarde), false sinon
## (creature non capturee, cout invalide, ou XP insuffisant).
func faire_evoluer_creature(creature_id: String) -> bool:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	if not capturees.has(creature_id):
		return false
	var stage_actuel: int = int(capturees[creature_id].get("stage", 1))
	var stage_cible: int = stage_actuel + 1
	var cout: int = cout_evolution_vers(stage_cible)
	if cout < 0 or get_xp_total() < cout:
		return false
	capturees[creature_id]["stage"] = stage_cible
	capturees[creature_id]["xp_investi"] = int(capturees[creature_id].get("xp_investi", 0)) + cout
	data["creatures_capturees"] = capturees
	data["xp_total"] = get_xp_total() - cout
	save_game()
	return true

## --- Surnom (personnalisation, distinct du nom d'espece) ---

func get_surnom_creature(creature_id: String) -> String:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	return String(capturees.get(creature_id, {}).get("surnom", ""))

func definir_surnom_creature(creature_id: String, surnom: String) -> void:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	if not capturees.has(creature_id):
		return
	capturees[creature_id]["surnom"] = surnom.strip_edges()
	data["creatures_capturees"] = capturees
	save_game()

## --- Berries (baies) : inventaire du joueur ---
## Chaque berry possedee est representee par son seul "skin" (1 a 10,
## purement cosmetique - voir BerryAssetUtil). L'inventaire est un
## simple Array[int], un element par berry possedee.

## Retourne l'inventaire sous forme d'Array[int]. Normalise chaque
## element via int() : apres un aller-retour JSON (sauvegarde/rechargement),
## les nombres reviennent en float (JSON ne distingue pas int/float), ce
## qui casserait une comparaison stricte comme `[9] == [9.0]` (fausse en
## GDScript pour le contenu d'un Array, contrairement a `9 == 9.0` qui
## est vraie) — meme piege que celui deja evite ailleurs dans ce fichier
## via int(...) sur "stage"/"xp_investi"/"berries_recues".
func get_berries_inventaire() -> Array:
	var brut: Array = data.get("berries_inventaire", [])
	var normalise: Array = []
	for skin in brut:
		normalise.append(int(skin))
	return normalise

## Ajoute une berry au skin donne (utilise par la distribution de fin de
## tableau, Phase 6 - pas encore branchee) ou un skin aleatoire si omis
## (utilise par le bouton de debug de l'ecran Roster en attendant).
func ajouter_berry(skin: int = -1) -> int:
	var skin_final: int = skin if skin > 0 else BerryAssetUtil.skin_aleatoire()
	var inventaire: Array = get_berries_inventaire()
	inventaire.append(skin_final)
	data["berries_inventaire"] = inventaire
	save_game()
	return skin_final

## Retire la berry a "index_inventaire" (ordre de get_berries_inventaire()).
## Retourne false si l'index est invalide (rien de retire, rien de sauve).
func consommer_berry(index_inventaire: int) -> bool:
	var inventaire: Array = get_berries_inventaire()
	if index_inventaire < 0 or index_inventaire >= inventaire.size():
		return false
	inventaire.remove_at(index_inventaire)
	data["berries_inventaire"] = inventaire
	save_game()
	return true

## --- Affection par creature (berries donnees) et deblocage "glow" ---
## Une creature devient "glow" a partir de SEUIL_GLOW berries recues
## (nouveau palier visuel, independant/au-dela des stades d'evolution).

const SEUIL_GLOW := 20

func get_affection_creature(creature_id: String) -> int:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	return int(capturees.get(creature_id, {}).get("berries_recues", 0))

func est_glow_creature(creature_id: String) -> bool:
	return get_affection_creature(creature_id) >= SEUIL_GLOW

## Donne une berry (deja retiree de l'inventaire via consommer_berry) a
## une creature : incremente son affection et sauvegarde. Retourne la
## nouvelle affection totale.
func donner_berry_a_creature(creature_id: String) -> int:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	if not capturees.has(creature_id):
		return 0
	var nouvelle_affection: int = int(capturees[creature_id].get("berries_recues", 0)) + 1
	capturees[creature_id]["berries_recues"] = nouvelle_affection
	data["creatures_capturees"] = capturees
	save_game()
	return nouvelle_affection

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
