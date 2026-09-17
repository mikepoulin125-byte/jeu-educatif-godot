extends Control
## Widget "croissant_decroissant" : une suite de nombres affichee en
## texte, choix binaire Croissant/Decroissant. Resout %Nom a la demande
## (voir widget_pair_impair.gd pour le pourquoi).

signal reponse_donnee(correcte: bool)

var _reponse_attendue: String = ""
var _connecte: bool = false

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	var suite: Array = question.get("suite", [])
	var textes := []
	for n in suite:
		textes.append(str(int(n)))
	var label_suite: Label = %LabelSuite
	label_suite.text = ", ".join(textes)
	_reponse_attendue = String(question.get("reponse", ""))
	var bouton_croissant: Button = %BoutonCroissant
	var bouton_decroissant: Button = %BoutonDecroissant
	bouton_croissant.disabled = false
	bouton_decroissant.disabled = false

func _connecter() -> void:
	if _connecte:
		return
	var bouton_croissant: Button = %BoutonCroissant
	var bouton_decroissant: Button = %BoutonDecroissant
	bouton_croissant.pressed.connect(func(): _repondre("croissant"))
	bouton_decroissant.pressed.connect(func(): _repondre("decroissant"))
	_connecte = true

func _repondre(choix: String) -> void:
	var bouton_croissant: Button = %BoutonCroissant
	var bouton_decroissant: Button = %BoutonDecroissant
	bouton_croissant.disabled = true
	bouton_decroissant.disabled = true
	reponse_donnee.emit(choix == _reponse_attendue)
