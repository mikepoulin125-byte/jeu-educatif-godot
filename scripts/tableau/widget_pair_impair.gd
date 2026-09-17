extends Control
## Widget de reponse pour la matiere "pair_impair" (choix binaire).
## Contrat commun a tous les widgets de scripts/tableau/ :
## configurer(question: Dictionary, contexte: Dictionary) -> void
## signal reponse_donnee(correcte: bool)
##
## Resout %Nom a la demande (pas de cache @onready) : ce widget est
## instancie puis configure() immediatement par ecran_tableau.gd, avant
## que _ready() ne soit forcement passe (meme piege documente pour
## CarteMatiere/CarteCreature en Phase 3).

signal reponse_donnee(correcte: bool)

var _reponse_attendue: String = ""
var _boutons_connectes: bool = false

func _ready() -> void:
	_connecter_boutons()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter_boutons()
	var label_nombre: Label = %LabelNombre
	label_nombre.text = str(int(question.get("nombre", 0)))
	_reponse_attendue = String(question.get("reponse", ""))
	var bouton_pair: Button = %BoutonPair
	var bouton_impair: Button = %BoutonImpair
	bouton_pair.disabled = false
	bouton_impair.disabled = false

func _connecter_boutons() -> void:
	if _boutons_connectes:
		return
	var bouton_pair: Button = %BoutonPair
	var bouton_impair: Button = %BoutonImpair
	bouton_pair.pressed.connect(func(): _repondre("pair"))
	bouton_impair.pressed.connect(func(): _repondre("impair"))
	_boutons_connectes = true

func _repondre(choix: String) -> void:
	var bouton_pair: Button = %BoutonPair
	var bouton_impair: Button = %BoutonImpair
	bouton_pair.disabled = true
	bouton_impair.disabled = true
	reponse_donnee.emit(choix == _reponse_attendue)
