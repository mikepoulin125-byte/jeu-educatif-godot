extends Control
## Widget "plan_cartesien". Pour l'instant, un seul type de question
## existe (tableau 1, badge 4 - demande de Mike : familiariser l'enfant
## avec un vrai plan cartesien AVANT de lui demander d'y interagir) :
## le plan est dessine (PlanCartesienView - axes flesches + quadrillage,
## MEME visuel prevu pour tous les tableaux du badge) avec UN SEUL axe
## affiche au complet et l'autre totalement vide sauf une graduation
## mise en evidence (cercle rouge) ; l'enfant ecrit le chiffre qui va a
## cet endroit (meme pattern de saisie que widget_terme_manquant.gd).
## D'autres types de question (ex. cliquer une intersection) seront
## ajoutes ici au fur et a mesure des prochains tableaux.
##
## Resout %Nom a la demande (voir widget_pair_impair.gd pour le
## pourquoi).

signal reponse_donnee(correcte: bool)

var _reponse_attendue: int = 0
var _connecte: bool = false

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	var taille: int = int(question.get("taille_grille", 5))
	var increment: int = int(question.get("increment", 1))
	var axe: String = String(question.get("axe_manquant", "x"))
	var position: int = int(question.get("position", 0))
	_reponse_attendue = int(question.get("reponse", (position + 1) * increment))

	var etiquettes_completes := []
	for i in range(1, taille + 1):
		etiquettes_completes.append(str(i * increment))
	var etiquettes_vides := []
	etiquettes_vides.resize(taille)

	var vue: PlanCartesienView = %Vue
	if axe == "x":
		vue.configurer(taille, etiquettes_vides, etiquettes_completes, position, -1)
	else:
		vue.configurer(taille, etiquettes_completes, etiquettes_vides, -1, position)

	var label_consigne: Label = %LabelConsigne
	var nom_axe := "X" if axe == "x" else "Y"
	label_consigne.text = "Quel nombre va dans le rond rouge de l'axe des %s ?" % nom_axe

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
