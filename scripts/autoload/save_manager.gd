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
	return {"stage": 1, "xp_investi": 0, "xp_investi_stade_actuel": 0, "surnom": "", "berries_recues": 0}

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
		save_game()

func get_creatures_vues() -> Array:
	return data.get("creatures_vues", [])

## --- Rencontres : quelle creature sauvage est associee a chaque tableau ---
## Le tirage au hasard (section 9.1 de la spec) n'a lieu qu'UNE fois par
## tableau (matiere+niveau) : une fois tiree, la creature reste associee
## a ce tableau pour toujours (y compris apres un echec/reessai), pour
## respecter "le tableau est scripte, la meme creature apparait" — voir
## docs/phases/phase_07_rencontre_capture.md.

func get_creature_rencontre(tableau_id: String) -> String:
	return String(data.get("rencontres", {}).get(tableau_id, ""))

func definir_creature_rencontre(tableau_id: String, creature_id: String) -> void:
	var rencontres: Dictionary = data.get("rencontres", {})
	rencontres[tableau_id] = creature_id
	data["rencontres"] = rencontres
	save_game()

func capturer_creature(creature_id: String) -> void:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	if not capturees.has(creature_id):
		capturees[creature_id] = _nouvelle_entree_creature()
	data["creatures_capturees"] = capturees
	save_game()

func get_creatures_capturees() -> Dictionary:
	return data.get("creatures_capturees", {})

func get_stage_creature(creature_id: String) -> int:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	return int(capturees.get(creature_id, {}).get("stage", 1))

func get_xp_investi_creature(creature_id: String) -> int:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	return int(capturees.get(creature_id, {}).get("xp_investi", 0))

## --- Creature principale (celle qui accompagne le joueur dans les tableaux) ---
## Choisie explicitement depuis le Roster ("Accompagne-moi !"). Tant que le
## joueur n'a rien choisi, repli par defaut : le starter, sinon la
## premiere creature capturee (ordre du dictionnaire de sauvegarde) —
## decision documentee dans docs/phases/phase_06_scenes_tableau.md, pour
## qu'une creature "principale" existe toujours des qu'au moins une
## creature est capturee (le starter l'est toujours).

func get_creature_principale_id() -> String:
	var choisie: String = String(data.get("creature_principale_id", ""))
	var capturees := get_creatures_capturees()
	if not choisie.is_empty() and capturees.has(choisie):
		return choisie
	var starter: String = String(data.get("starter_id", ""))
	if not starter.is_empty() and capturees.has(starter):
		return starter
	var ids := capturees.keys()
	return String(ids[0]) if ids.size() > 0 else ""

## Ne fait rien si "creature_id" n'est pas une creature capturee (evite
## de definir une creature principale invalide).
func definir_creature_principale(creature_id: String) -> void:
	if not get_creatures_capturees().has(creature_id):
		return
	data["creature_principale_id"] = creature_id
	save_game()

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

## --- Attribution d'XP par petits bonds (Phase 8, demande de Mike) ---
## Remplace l'ancienne attribution "tout le cout d'un coup" cote Roster :
## chaque clic ajoute un petit montant (10 XP) vers le PROCHAIN palier
## de CETTE creature specifiquement, retire du total du joueur.
## L'evolution se declenche automatiquement des que ce palier est
## atteint. "stage_max" vient de DataManager (creatures.json) et est
## fourni par l'appelant, jamais lu ici — meme separation des
## responsabilites que pour cout_evolution_vers() ci-dessus.

## {"applique": bool, "evolue": bool, "nouveau_stade": int}. "applique"
## reste false sans rien modifier si la creature n'est pas capturee, est
## deja au stade maximal, ou si le joueur n'a pas assez de XP pour ce
## bond precis.
func ajouter_xp_creature(creature_id: String, montant: int, stage_max: int) -> Dictionary:
	var resultat := {"applique": false, "evolue": false, "nouveau_stade": 0}
	var capturees: Dictionary = data.get("creatures_capturees", {})
	if not capturees.has(creature_id):
		return resultat
	var stage_actuel: int = int(capturees[creature_id].get("stage", 1))
	if stage_actuel >= stage_max:
		return resultat
	if get_xp_total() < montant:
		return resultat

	var cout: int = cout_evolution_vers(stage_actuel + 1)
	var progression: int = int(capturees[creature_id].get("xp_investi_stade_actuel", 0)) + montant

	data["xp_total"] = get_xp_total() - montant
	capturees[creature_id]["xp_investi"] = int(capturees[creature_id].get("xp_investi", 0)) + montant
	resultat["applique"] = true

	if cout >= 0 and progression >= cout:
		capturees[creature_id]["stage"] = stage_actuel + 1
		capturees[creature_id]["xp_investi_stade_actuel"] = 0
		resultat["evolue"] = true
		resultat["nouveau_stade"] = stage_actuel + 1
	else:
		capturees[creature_id]["xp_investi_stade_actuel"] = progression

	data["creatures_capturees"] = capturees
	save_game()
	return resultat

## Progression actuelle vers le PROCHAIN palier de cette creature (0 si
## non capturee) — PAS le total XP du joueur. Corrige le bug ou la barre
## de chaque creature affichait le meme total XP du portefeuille du
## joueur (ex. 200 XP affiche identique sur toutes les creatures).
func get_progression_stade_creature(creature_id: String) -> int:
	var capturees: Dictionary = data.get("creatures_capturees", {})
	return int(capturees.get(creature_id, {}).get("xp_investi_stade_actuel", 0))

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

## "total" = nombre de questions de CET essai (toujours 10 pour un niveau
## normal ; variable pour l'examen, voir ExamenUtil). Stocke a cote de
## meilleur_score pour un affichage correct ("N/total") meme quand le
## total a pu varier d'un essai a l'autre (examen construit avec moins
## de 10 questions faute de contenu disponible).
func set_progression_niveau(matiere_id: String, niveau_id: String, reussi: bool, score: int, debloque: bool = true, total: int = 10) -> void:
	var progression: Dictionary = data.get("progression", {})
	if not progression.has(matiere_id):
		progression[matiere_id] = {"niveaux": {}}
	var niveaux: Dictionary = progression[matiere_id]["niveaux"]
	var precedent: Dictionary = niveaux.get(niveau_id, {})
	var score_precedent: int = int(precedent.get("meilleur_score", 0))
	var meilleur_score: int = max(score_precedent, score)
	# Le total accompagne toujours le meilleur score des DEUX essais compares
	# (et non un total "record" separe, qui n'aurait pas de sens a comparer).
	var meilleur_total: int = int(precedent.get("meilleur_total", total)) if score_precedent >= score else total
	niveaux[niveau_id] = {
		"debloque": debloque or bool(precedent.get("debloque", false)),
		"reussi": reussi or bool(precedent.get("reussi", false)),
		"meilleur_score": meilleur_score,
		"meilleur_total": meilleur_total
	}
	progression[matiere_id]["niveaux"] = niveaux
	data["progression"] = progression
	save_game()

func est_niveau_debloque(matiere_id: String, niveau_id: String) -> bool:
	var prog := get_progression_matiere(matiere_id)
	var niveaux: Dictionary = prog.get("niveaux", {})
	return bool(niveaux.get(niveau_id, {}).get("debloque", false))

## --- Questions ratees (pour l'examen, section "11e niveau") ---

const MAX_QUESTIONS_RATEES_PAR_MATIERE := 200

## Enregistre une question ratee pour alimenter le pool de l'examen de
## cette matiere. Deduplique (une meme question ratee plusieurs fois ne
## cree qu'une seule entree) et plafonne la liste (retire la plus
## ancienne au-dela de MAX_QUESTIONS_RATEES_PAR_MATIERE, ecran de secours
## contre une croissance illimitee sur une tres longue partie).
func ajouter_question_ratee(matiere_id: String, question: Dictionary, contexte: Dictionary) -> void:
	var toutes: Dictionary = data.get("questions_ratees", {})
	var liste: Array = toutes.get(matiere_id, [])
	var entree := {"question": question, "contexte": contexte}
	if liste.has(entree):
		return
	liste.append(entree)
	if liste.size() > MAX_QUESTIONS_RATEES_PAR_MATIERE:
		liste = liste.slice(liste.size() - MAX_QUESTIONS_RATEES_PAR_MATIERE)
	toutes[matiere_id] = liste
	data["questions_ratees"] = toutes
	save_game()

## Copie de la liste (jamais null), chaque entree = {"question": Dictionary, "contexte": Dictionary}.
func get_questions_ratees(matiere_id: String) -> Array:
	var toutes: Dictionary = data.get("questions_ratees", {})
	var liste: Array = toutes.get(matiere_id, [])
	return liste.duplicate(true)
