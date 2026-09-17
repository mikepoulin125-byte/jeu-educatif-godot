extends VBoxContainer
## Carte reutilisable pour un badge de matiere du hub : cercle blanc avec
## icone reelle (assets/ui/) ou placeholder colore (couleur+symbole de
## matieres.json), libelle blanc en dessous. Style inspire du langage
## visuel generique envoye par Mike (bouton rond blanc + icone centree +
## libelle dessous, sur fond a bandes diagonales) — aucun asset externe
## reproduit, tout est genere ou fourni par les donnees du projet.
##
## Comme les autres cartes : configurer() resout les noeuds enfants via
## %Nom a chaque appel (fonctionne des instantiate(), pas besoin
## d'attendre _ready()).

signal choisie(matiere_id: String)

var _matiere_id: String = ""
var _pressed_connecte: bool = false

func _ready() -> void:
	_connecter_bouton()

func configurer(matiere_data: Dictionary) -> void:
	_matiere_id = String(matiere_data.get("id", ""))
	_connecter_bouton()

	var icone_id: String = String(matiere_data.get("icone", ""))
	var texture_icone: TextureRect = %TextureIcone
	var placeholder_icone: Panel = %PlaceholderIcone
	var label_symbole: Label = %LabelSymbole

	var texture := UiIconUtil.charger_texture(icone_id)
	if texture != null:
		texture_icone.texture = texture
		texture_icone.visible = true
		placeholder_icone.visible = false
	else:
		texture_icone.visible = false
		placeholder_icone.visible = true
		var couleur_hex: String = String(matiere_data.get("couleur", "#808080"))
		var style: StyleBoxFlat = placeholder_icone.get_theme_stylebox("panel").duplicate()
		style.bg_color = Color(couleur_hex)
		placeholder_icone.add_theme_stylebox_override("panel", style)
		label_symbole.text = String(matiere_data.get("symbole", "?"))

	var label_nom: Label = %LabelNom
	label_nom.text = String(matiere_data.get("nom", _matiere_id))

	var bouton: Button = %BoutonCercle
	bouton.tooltip_text = String(matiere_data.get("description", ""))

func _connecter_bouton() -> void:
	if _pressed_connecte:
		return
	var bouton: Button = %BoutonCercle
	bouton.pressed.connect(func(): choisie.emit(_matiere_id))
	_pressed_connecte = true
