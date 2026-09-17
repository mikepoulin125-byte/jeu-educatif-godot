extends Control
## Boite de dialogue narrative : affiche les lignes de data/intro.json une
## a une, avec un effet de texte progressif ("machine a ecrire").
## Un clic/Espace/Entree complete la ligne courante, ou passe a la suivante.

const VITESSE_CARACTERES_PAR_SEC := 40.0

@onready var label_dialogue: Label = %LabelDialogue
@onready var label_indice: Label = %LabelIndice

var _lignes: Array = []
var _index_ligne: int = 0
var _texte_complet: String = ""
var _caracteres_affiches: float = 0.0
var _en_cours_de_revelation: bool = false

func _ready() -> void:
	_lignes = DataManager.get_lignes_intro()
	if _lignes.is_empty():
		_aller_vers_selection_starter()
		return
	_afficher_ligne(0)

func _process(delta: float) -> void:
	if not _en_cours_de_revelation:
		return
	_caracteres_affiches += VITESSE_CARACTERES_PAR_SEC * delta
	var nb := int(_caracteres_affiches)
	if nb >= _texte_complet.length():
		label_dialogue.text = _texte_complet
		_en_cours_de_revelation = false
		label_indice.visible = true
	else:
		label_dialogue.text = _texte_complet.substr(0, nb)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_avancer()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_avancer()
		get_viewport().set_input_as_handled()

func _avancer() -> void:
	if _en_cours_de_revelation:
		label_dialogue.text = _texte_complet
		_en_cours_de_revelation = false
		label_indice.visible = true
		return
	_index_ligne += 1
	if _index_ligne >= _lignes.size():
		_aller_vers_selection_starter()
	else:
		_afficher_ligne(_index_ligne)

func _afficher_ligne(index: int) -> void:
	_texte_complet = String(_lignes[index])
	_caracteres_affiches = 0.0
	_en_cours_de_revelation = true
	label_dialogue.text = ""
	label_indice.visible = false

func _aller_vers_selection_starter() -> void:
	get_tree().change_scene_to_file("res://scenes/SelectionStarter.tscn")
