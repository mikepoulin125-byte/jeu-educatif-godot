extends Button
## Carte/bouton reutilisable pour un badge de matiere du hub (icone reelle
## ou placeholder, nom, description). Toute la carte est cliquable
## (le noeud racine est lui-meme un Button, texte vide, le visuel est
## gere par les enfants).
##
## Meme principe que CarteCreature : configurer() resout les noeuds
## enfants via %Nom a chaque appel (fonctionne des instantiate(), pas
## besoin d'attendre _ready()).

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
	var placeholder_icone: ColorRect = %PlaceholderIcone
	var label_placeholder: Label = %LabelPlaceholderIcone

	var texture := UiIconUtil.charger_texture(icone_id)
	if texture != null:
		texture_icone.texture = texture
		texture_icone.visible = true
		placeholder_icone.visible = false
	else:
		texture_icone.visible = false
		placeholder_icone.visible = true
		label_placeholder.text = icone_id if not icone_id.is_empty() else "?"

	var label_nom: Label = %LabelNom
	var label_description: Label = %LabelDescription
	label_nom.text = String(matiere_data.get("nom", _matiere_id))
	label_description.text = String(matiere_data.get("description", ""))

func _connecter_bouton() -> void:
	if _pressed_connecte:
		return
	pressed.connect(func(): choisie.emit(_matiere_id))
	_pressed_connecte = true
