extends Control
## Ecran de selection de niveau (section 8 de la spec) : 10 tableaux pour
## la matiere choisie au Hub (GameState.matiere_courante_id), plus une
## 11e carte "Examen" (Phase 8) qui repose les questions ratees a
## travers ces 10 niveaux (voir ExamenUtil + SaveManager.get_questions_ratees()).
## Progression strictement lineaire : niveau 1 toujours debloque, niveau
## n+1 debloque seulement si niveau n reussi (>= 70%) — l'etat
## "debloque" du niveau 1 n'est jamais lu depuis la sauvegarde, il est
## implicite (toujours vrai), les niveaux 2 a 10 dependent de
## SaveManager.est_niveau_debloque().
##
## L'examen se debloque des que le niveau 1 a ete tente au moins une
## fois (qu'il soit reussi ou non) : condition simple et suffisante pour
## garantir un pool d'au moins 10 questions "deja vues" pour le
## completer si le joueur n'a pas encore assez d'erreurs accumulees
## (voir ExamenUtil pour le detail de cette decision).
##
## Chemin de terre procedural (CheminNiveaux) reliant les 10 niveaux
## entre eux (PAS l'examen, visuellement separe) : purement decoratif,
## les points sont calcules ici a partir de la position REELLE de
## chaque carte apres que le GridContainer ait fait son propre layout
## (une frame de delai, voir _ready()).

const NB_NIVEAUX := 10
const CarteNiveauScene := preload("res://scenes/components/CarteNiveau.tscn")
## Sentinelle emise par CarteNiveau.choisi() pour la carte "Examen"
## (les numeros de niveau normaux vont de 1 a NB_NIVEAUX, jamais 0).
const NUMERO_EXAMEN := 0

@onready var label_xp: Label = %LabelXp
@onready var bouton_retour: Button = %BoutonRetour
@onready var label_titre: Label = %LabelTitre
@onready var grille_niveaux: GridContainer = %GrilleNiveaux
@onready var chemin_niveaux: CheminNiveaux = %CheminNiveaux
@onready var zone_examen: CenterContainer = %ZoneExamen

func _ready() -> void:
	bouton_retour.pressed.connect(func(): SceneTransition.changer_scene("res://scenes/Hub.tscn"))
	_actualiser_label_xp()
	_afficher_titre()
	_peupler_niveaux()
	_peupler_examen()
	_dessiner_chemin.call_deferred()

func _actualiser_label_xp() -> void:
	label_xp.text = "XP : %d" % SaveManager.get_xp_total()

func _afficher_titre() -> void:
	var matiere := DataManager.get_matiere_by_id(GameState.matiere_courante_id)
	label_titre.text = String(matiere.get("nom", GameState.matiere_courante_id))

func _peupler_niveaux() -> void:
	for enfant in grille_niveaux.get_children():
		enfant.queue_free()

	var matiere_id := GameState.matiere_courante_id
	var progression := SaveManager.get_progression_matiere(matiere_id)
	var niveaux_progression: Dictionary = progression.get("niveaux", {})

	for numero in range(1, NB_NIVEAUX + 1):
		var niveau_id := "niveau_%02d" % numero
		var niveau_data := DataManager.load_niveau("%s_%s" % [matiere_id, niveau_id])
		var nom: String = String(niveau_data.get("nom", "Niveau %d" % numero))

		var infos: Dictionary = niveaux_progression.get(niveau_id, {})
		var debloque: bool = numero == 1 or bool(infos.get("debloque", false))
		var reussi: bool = bool(infos.get("reussi", false))
		var meilleur_score: int = int(infos.get("meilleur_score", 0))
		var meilleur_total: int = int(infos.get("meilleur_total", 10))

		var etat := "verrouille"
		if debloque:
			etat = "reussi" if reussi else "disponible"

		var carte := CarteNiveauScene.instantiate()
		grille_niveaux.add_child(carte)
		carte.configurer(numero, nom, etat, meilleur_score, meilleur_total)
		carte.choisi.connect(_on_niveau_choisi)

## Carte "Examen" (11e), placee sous la grille (ZoneExamen), pas dans le
## GridContainer — voir l'entete du fichier pour le detail du placement.
func _peupler_examen() -> void:
	for enfant in zone_examen.get_children():
		enfant.queue_free()

	var matiere_id := GameState.matiere_courante_id
	var progression := SaveManager.get_progression_matiere(matiere_id)
	var niveaux_progression: Dictionary = progression.get("niveaux", {})

	var examen_debloque: bool = niveaux_progression.has("niveau_01")
	var infos_examen: Dictionary = niveaux_progression.get("examen", {})
	var reussi: bool = bool(infos_examen.get("reussi", false))
	var meilleur_score: int = int(infos_examen.get("meilleur_score", 0))
	var meilleur_total: int = int(infos_examen.get("meilleur_total", ExamenUtil.NB_QUESTIONS_EXAMEN))

	var etat := "verrouille"
	if examen_debloque:
		etat = "reussi" if reussi else "disponible"

	var carte := CarteNiveauScene.instantiate()
	zone_examen.add_child(carte)
	carte.configurer_examen(etat, meilleur_score, meilleur_total)
	carte.afficher_icone_coin(ExamenAssetUtil.charger_icone(matiere_id))
	carte.choisi.connect(_on_niveau_choisi)

## Attend que GrilleNiveaux ait fini son propre passage de layout (les
## positions des cartes ne sont fiables qu'apres, meme piege de timing
## que documente pour @onready/Timer en Phase 8) avant de calculer les
## points du chemin.
func _dessiner_chemin() -> void:
	await get_tree().process_frame
	var points := []
	for carte in grille_niveaux.get_children():
		points.append(carte.position + carte.size / 2.0)
	chemin_niveaux.definir_points(points)

func _on_niveau_choisi(numero: int) -> void:
	if numero == NUMERO_EXAMEN:
		GameState.niveau_courant_id = "examen"
	else:
		GameState.niveau_courant_id = "niveau_%02d" % numero
	SceneTransition.changer_scene("res://scenes/EcranTableau.tscn")
