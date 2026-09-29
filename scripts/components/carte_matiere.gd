extends VBoxContainer
## Carte reutilisable pour un badge de matiere du hub : cercle blanc avec
## icone reelle ou placeholder colore (couleur+symbole de matieres.json).
## Style inspire du langage visuel generique envoye par Mike (bouton
## rond blanc + icone centree, sur fond a bandes diagonales) — aucun
## asset externe reproduit, tout est genere ou fourni par les donnees
## du projet.
##
## Phase 8 (raffinement demande par Mike) : l'icone reelle est la MEME
## image que celle de la carte "Examen" de cette matiere
## (assets/ui/examen/exam_<id>_icon.png, voir ExamenAssetUtil) — un seul
## fichier par matiere, reutilise aux deux endroits, plutot que deux
## conventions de nommage separees. Le libelle sous le cercle (LabelNom)
## est cache visuellement (mais toujours rempli programmatiquement, pour
## garder le tooltip/l'accessibilite et ne pas casser les tests qui en
## verifient le contenu).
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

	var texture_icone: TextureRect = %TextureIcone
	var placeholder_icone: Panel = %PlaceholderIcone
	var label_symbole: Label = %LabelSymbole

	var texture := ExamenAssetUtil.charger_icone(_matiere_id)
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
