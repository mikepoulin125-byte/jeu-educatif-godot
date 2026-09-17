extends Control
## Ecran de selection de niveau (section 8 de la spec) : 10 tableaux pour
## la matiere choisie au Hub (GameState.matiere_courante_id).
## Progression strictement lineaire : niveau 1 toujours debloque, niveau
## n+1 debloque seulement si niveau n reussi (>= 7/10) — l'etat
## "debloque" du niveau 1 n'est jamais lu depuis la sauvegarde, il est
## implicite (toujours vrai), les niveaux 2 a 10 dependent de
## SaveManager.est_niveau_debloque().

const NB_NIVEAUX := 10
const CarteNiveauScene := preload("res://scenes/components/CarteNiveau.tscn")

@onready var label_xp: Label = %LabelXp
@onready var bouton_retour: Button = %BoutonRetour
@onready var label_titre: Label = %LabelTitre
@onready var grille_niveaux: GridContainer = %GrilleNiveaux

func _ready() -> void:
	bouton_retour.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Hub.tscn"))
	_actualiser_label_xp()
	_afficher_titre()
	_peupler_niveaux()

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

		var etat := "verrouille"
		if debloque:
			etat = "reussi" if reussi else "disponible"

		var carte := CarteNiveauScene.instantiate()
		grille_niveaux.add_child(carte)
		carte.configurer(numero, nom, etat, meilleur_score)
		carte.choisi.connect(_on_niveau_choisi)

func _on_niveau_choisi(numero: int) -> void:
	GameState.niveau_courant_id = "niveau_%02d" % numero
	get_tree().change_scene_to_file("res://scenes/EcranTableauPlaceholder.tscn")
