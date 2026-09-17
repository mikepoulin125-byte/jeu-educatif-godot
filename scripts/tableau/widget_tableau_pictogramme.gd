extends Control
## Widget "tableau_pictogramme" : un graphique a bandes (contexte.graphique,
## partage par les 10 questions du niveau) + une question numerique sur
## ce graphique a chaque fois. Barres dessinees avec de simples
## ColorRect (pas d'assets requis). Resout %Nom a la demande (voir
## widget_pair_impair.gd pour le pourquoi).

signal reponse_donnee(correcte: bool)

const HAUTEUR_MAX_BARRE := 180.0
const LARGEUR_BARRE := 70.0

var _reponse_attendue: int = 0
var _graphique_affiche: bool = false
var _connecte: bool = false

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, contexte: Dictionary) -> void:
	_connecter()
	var graphique: Dictionary = contexte.get("graphique", {})
	if not _graphique_affiche:
		_construire_graphique(graphique)
		_graphique_affiche = true

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

func _construire_graphique(graphique: Dictionary) -> void:
	var label_titre: Label = %LabelTitre
	label_titre.text = String(graphique.get("titre", ""))
	var barres: Array = graphique.get("barres", [])
	var valeur_max := 1
	for barre in barres:
		valeur_max = max(valeur_max, int(barre.get("valeur", 0)))

	var zone_barres: HBoxContainer = %ZoneBarres
	for enfant in zone_barres.get_children():
		enfant.queue_free()

	for barre in barres:
		var valeur: int = int(barre.get("valeur", 0))
		var hauteur: float = (float(valeur) / float(valeur_max)) * HAUTEUR_MAX_BARRE

		var colonne := VBoxContainer.new()
		colonne.custom_minimum_size = Vector2(LARGEUR_BARRE, 0)
		colonne.alignment = BoxContainer.ALIGNMENT_END

		var label_valeur := Label.new()
		label_valeur.text = str(valeur)
		label_valeur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(LARGEUR_BARRE, hauteur)
		rect.color = Color(0.23, 0.51, 0.96, 1)

		var label_nom := Label.new()
		label_nom.text = String(barre.get("categorie", ""))
		label_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_nom.autowrap_mode = TextServer.AUTOWRAP_WORD

		colonne.add_child(label_valeur)
		colonne.add_child(rect)
		colonne.add_child(label_nom)
		zone_barres.add_child(colonne)

func _valider() -> void:
	var champ_reponse: LineEdit = %ChampReponse
	if not champ_reponse.text.is_valid_int():
		return
	var valeur := int(champ_reponse.text)
	champ_reponse.editable = false
	var bouton_valider: Button = %BoutonValider
	bouton_valider.disabled = true
	reponse_donnee.emit(valeur == _reponse_attendue)
