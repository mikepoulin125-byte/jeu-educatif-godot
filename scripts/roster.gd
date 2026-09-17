extends Control
## Ecran Roster (section 7 de la spec) : liste des creatures capturees,
## selection -> stats/stade/XP investi, bouton "Attribuer XP" pour faire
## evoluer la creature selectionnee (300 XP -> stade 2, 500 XP -> stade
## 3). Le stade maximal d'une creature vient de creatures.json (champ
## "stages"), le cout et la deduction d'XP viennent de SaveManager.

const CarteCreatureRosterScene := preload("res://scenes/components/CarteCreatureRoster.tscn")

@onready var label_xp: Label = %LabelXp
@onready var bouton_retour: Button = %BoutonRetour
@onready var grille_creatures: GridContainer = %GrilleCreatures

@onready var texture_detail: TextureRect = %TextureDetail
@onready var placeholder_detail: ColorRect = %PlaceholderDetail
@onready var label_placeholder_detail: Label = %LabelPlaceholderDetail
@onready var label_nom_detail: Label = %LabelNomDetail
@onready var label_stade_detail: Label = %LabelStadeDetail
@onready var label_xp_investi_detail: Label = %LabelXpInvestiDetail
@onready var bouton_attribuer_xp: Button = %BoutonAttribuerXp
@onready var label_statut: Label = %LabelStatut

var _cartes_par_id: Dictionary = {}
var _creature_selectionnee_id: String = ""

func _ready() -> void:
	bouton_retour.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Hub.tscn"))
	bouton_attribuer_xp.pressed.connect(_on_attribuer_xp_presse)

	_actualiser_label_xp()
	_peupler_liste()

func _actualiser_label_xp() -> void:
	label_xp.text = "XP : %d" % SaveManager.get_xp_total()

func _peupler_liste() -> void:
	var capturees: Dictionary = SaveManager.get_creatures_capturees()
	var premier_id := ""
	for creature_id in capturees.keys():
		if not DataManager.creatures.has(creature_id):
			continue
		if premier_id.is_empty():
			premier_id = creature_id
		var carte := CarteCreatureRosterScene.instantiate()
		grille_creatures.add_child(carte)
		var stage := SaveManager.get_stage_creature(creature_id)
		carte.configurer(creature_id, DataManager.creatures[creature_id], stage)
		carte.selectionnee.connect(_selectionner_creature)
		_cartes_par_id[creature_id] = carte

	if not premier_id.is_empty():
		_selectionner_creature(premier_id)
	else:
		label_statut.text = "Aucune creature capturee."
		bouton_attribuer_xp.disabled = true

func _selectionner_creature(creature_id: String) -> void:
	if _cartes_par_id.has(_creature_selectionnee_id):
		_cartes_par_id[_creature_selectionnee_id].definir_selectionnee(false)

	_creature_selectionnee_id = creature_id
	if _cartes_par_id.has(creature_id):
		_cartes_par_id[creature_id].definir_selectionnee(true)

	_actualiser_details()

func _actualiser_details() -> void:
	var creature_data: Dictionary = DataManager.creatures.get(_creature_selectionnee_id, {})
	var stage_actuel := SaveManager.get_stage_creature(_creature_selectionnee_id)
	var stage_max: int = int(creature_data.get("stages", 1))
	var forms: Dictionary = creature_data.get("forms", {})
	var names: Dictionary = creature_data.get("names", {})
	var sprite_id: String = String(forms.get("stage%d" % stage_actuel, ""))

	var texture := SpriteUtil.charger_texture(sprite_id)
	if texture != null:
		texture_detail.texture = texture
		texture_detail.visible = true
		placeholder_detail.visible = false
	else:
		texture_detail.visible = false
		placeholder_detail.visible = true
		label_placeholder_detail.text = sprite_id if not sprite_id.is_empty() else "?"

	label_nom_detail.text = String(names.get("stage%d" % stage_actuel, _creature_selectionnee_id))
	label_stade_detail.text = "Stade %d / %d" % [stage_actuel, stage_max]
	label_xp_investi_detail.text = "XP investi : %d" % SaveManager.get_xp_investi_creature(_creature_selectionnee_id)

	_actualiser_bouton_attribuer(stage_actuel, stage_max)

func _actualiser_bouton_attribuer(stage_actuel: int, stage_max: int) -> void:
	if stage_actuel >= stage_max:
		bouton_attribuer_xp.disabled = true
		bouton_attribuer_xp.text = "Stade maximal atteint"
		label_statut.text = ""
		return

	var cout: int = SaveManager.cout_evolution_vers(stage_actuel + 1)
	bouton_attribuer_xp.text = "Attribuer XP (%d)" % cout
	if SaveManager.get_xp_total() < cout:
		bouton_attribuer_xp.disabled = true
		label_statut.text = "XP insuffisant (%d requis)" % cout
	else:
		bouton_attribuer_xp.disabled = false
		label_statut.text = ""

func _on_attribuer_xp_presse() -> void:
	var reussi := SaveManager.faire_evoluer_creature(_creature_selectionnee_id)
	if not reussi:
		label_statut.text = "Evolution impossible."
		return

	label_statut.text = "Evolution reussie !"
	_actualiser_label_xp()
	_actualiser_details()

	var stage_actuel := SaveManager.get_stage_creature(_creature_selectionnee_id)
	if _cartes_par_id.has(_creature_selectionnee_id):
		_cartes_par_id[_creature_selectionnee_id].configurer(
			_creature_selectionnee_id,
			DataManager.creatures[_creature_selectionnee_id],
			stage_actuel
		)
