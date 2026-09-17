extends Control
## Widget "fractions" : choix multiple parmi 3 fractions textuelles
## (ex. "1/2", "1/3", "1/4"). Resout %Nom a la demande (voir
## widget_pair_impair.gd pour le pourquoi).

signal reponse_donnee(correcte: bool)

var _index_attendu: int = -1
var _repondu: bool = false
var _connecte: bool = false

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	var label_texte: Label = %LabelTexte
	label_texte.text = String(question.get("texte", ""))
	var choix: Array = question.get("choix", [])
	var boutons := [%BoutonChoix0, %BoutonChoix1, %BoutonChoix2]
	for i in range(boutons.size()):
		boutons[i].text = String(choix[i]) if i < choix.size() else ""
		boutons[i].disabled = false
	_index_attendu = int(question.get("reponse_index", -1))
	_repondu = false

func _connecter() -> void:
	if _connecte:
		return
	var boutons := [%BoutonChoix0, %BoutonChoix1, %BoutonChoix2]
	for i in range(boutons.size()):
		boutons[i].pressed.connect(_repondre.bind(i))
	_connecte = true

func _repondre(index: int) -> void:
	if _repondu:
		return
	_repondu = true
	var boutons := [%BoutonChoix0, %BoutonChoix1, %BoutonChoix2]
	for b in boutons:
		b.disabled = true
	reponse_donnee.emit(index == _index_attendu)
