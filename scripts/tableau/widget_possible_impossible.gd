extends Control
## Widget "possible_impossible" : enonce + choix binaire. Resout %Nom a
## la demande (voir widget_pair_impair.gd pour le pourquoi).

signal reponse_donnee(correcte: bool)

var _reponse_attendue: String = ""
var _connecte: bool = false

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	var label_texte: Label = %LabelTexte
	label_texte.text = String(question.get("texte", ""))
	_reponse_attendue = String(question.get("reponse", ""))
	var bouton_possible: Button = %BoutonPossible
	var bouton_impossible: Button = %BoutonImpossible
	bouton_possible.disabled = false
	bouton_impossible.disabled = false

func _connecter() -> void:
	if _connecte:
		return
	var bouton_possible: Button = %BoutonPossible
	var bouton_impossible: Button = %BoutonImpossible
	bouton_possible.pressed.connect(func(): _repondre("possible"))
	bouton_impossible.pressed.connect(func(): _repondre("impossible"))
	_connecte = true

func _repondre(choix: String) -> void:
	var bouton_possible: Button = %BoutonPossible
	var bouton_impossible: Button = %BoutonImpossible
	bouton_possible.disabled = true
	bouton_impossible.disabled = true
	reponse_donnee.emit(choix == _reponse_attendue)
