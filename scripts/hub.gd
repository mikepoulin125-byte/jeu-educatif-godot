extends Control
## Hub principal (section 6 de la spec) : 8 badges de matiere, XP total
## permanent en haut-gauche, bouton Roster permanent.

const CarteMatiereScene := preload("res://scenes/components/CarteMatiere.tscn")
const DUREE_FONDU_ENTREE := 0.45

@onready var label_xp: Label = %LabelXp
@onready var grille_matieres: GridContainer = %GrilleMatieres
@onready var bouton_roster: Button = %BoutonRoster
@onready var voile_entree: TransitionRadiale = %VoileEntree

func _ready() -> void:
	# Fondu radial depuis le blanc (centre en premier), notamment a
	# l'arrivee depuis l'ecran de chargement — voir
	# shaders/transition_radiale_blanc.gdshader.
	voile_entree.animer(1.0, 0.0, DUREE_FONDU_ENTREE)

	_actualiser_xp()
	bouton_roster.pressed.connect(_on_roster_presse)
	_peupler_matieres()

func _actualiser_xp() -> void:
	label_xp.text = "XP : %d" % SaveManager.get_xp_total()

func _peupler_matieres() -> void:
	for matiere in DataManager.matieres:
		var carte := CarteMatiereScene.instantiate()
		grille_matieres.add_child(carte)
		carte.configurer(matiere)
		carte.choisie.connect(_on_matiere_choisie)

func _on_matiere_choisie(matiere_id: String) -> void:
	GameState.matiere_courante_id = matiere_id
	# Phase 5 construira le vrai ecran de selection de niveau ; en
	# attendant, un placeholder minimal confirme que la navigation fonctionne.
	get_tree().change_scene_to_file("res://scenes/SelectionNiveau.tscn")

func _on_roster_presse() -> void:
	# Phase 4 construira le vrai ecran Roster ; placeholder minimal pour l'instant.
	get_tree().change_scene_to_file("res://scenes/Roster.tscn")
