extends Control
## Widget "terme_manquant" : equation textuelle ("7 - ? = 2"), champ
## numerique, reponse exacte attendue. Resout %Nom a la demande (voir
## widget_pair_impair.gd pour le pourquoi).

signal reponse_donnee(correcte: bool)

var _reponse_attendue: int = 0
var _connecte: bool = false

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	var label_texte: Label = %LabelTexte
	label_texte.text = String(question.get("texte", ""))
	_reponse_attendue = int(question.get("reponse", 0))
	var champ_reponse: LineEdit = %ChampReponse
	var bouton_valider: Button = %BoutonValider
	champ_reponse.text = ""
	champ_reponse.editable = true
	bouton_valider.disabled = false

func _connecter() -> void:
	if _connecte:
		return
	var champ_reponse: LineEdit = %ChampReponse
	var bouton_valider: Button = %BoutonValider
	bouton_valider.pressed.connect(_valider)
	champ_reponse.text_submitted.connect(func(_t): _valider())
	_connecte = true

func _valider() -> void:
	var champ_reponse: LineEdit = %ChampReponse
	if not champ_reponse.text.is_valid_int():
		return
	var valeur := int(champ_reponse.text)
	champ_reponse.editable = false
	var bouton_valider: Button = %BoutonValider
	bouton_valider.disabled = true
	reponse_donnee.emit(valeur == _reponse_attendue)
