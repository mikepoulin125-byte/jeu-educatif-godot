extends VBoxContainer
## Carte reutilisable pour une entree de la liste du Roster : sprite (au
## stade actuel de la creature) + nom, cliquable pour selectionner cette
## creature. Meme langage visuel que CarteMatiere (cercle blanc, bordure
## #CC0000, BoutonAnime), avec un etat "selectionnee" (fond teinte).
##
## configurer() resout les noeuds enfants via %Nom a chaque appel (pas
## besoin d'attendre _ready(), meme reflexe que les autres composants de
## ce projet).

signal selectionnee(creature_id: String)

var _creature_id: String = ""
var _pressed_connecte: bool = false
var _style_normal_base: StyleBoxFlat
var _style_selectionnee: StyleBoxFlat

func _ready() -> void:
	_connecter_bouton()

func configurer(creature_id: String, creature_data: Dictionary, stage_actuel: int) -> void:
	_creature_id = creature_id
	_connecter_bouton()

	var forms: Dictionary = creature_data.get("forms", {})
	var names: Dictionary = creature_data.get("names", {})
	var sprite_id: String = String(forms.get("stage%d" % stage_actuel, ""))

	var texture_rect: TextureRect = %TextureSprite
	var placeholder: ColorRect = %PlaceholderSprite
	var label_placeholder: Label = %LabelPlaceholder

	var texture := SpriteUtil.charger_texture(sprite_id)
	if texture != null:
		texture_rect.texture = texture
		texture_rect.visible = true
		placeholder.visible = false
	else:
		texture_rect.visible = false
		placeholder.visible = true
		label_placeholder.text = sprite_id if not sprite_id.is_empty() else "?"

	var label_nom: Label = %LabelNom
	label_nom.text = String(names.get("stage%d" % stage_actuel, creature_id))

func definir_selectionnee(valeur: bool) -> void:
	var bouton: Button = %BoutonCercle
	if valeur:
		if _style_selectionnee == null:
			_style_selectionnee = bouton.get_theme_stylebox("normal").duplicate()
			_style_selectionnee.bg_color = Color(1, 0.85, 0.85, 1)
		bouton.add_theme_stylebox_override("normal", _style_selectionnee)
	elif _style_normal_base != null:
		bouton.add_theme_stylebox_override("normal", _style_normal_base)

func _connecter_bouton() -> void:
	if _pressed_connecte:
		return
	var bouton: Button = %BoutonCercle
	if _style_normal_base == null:
		_style_normal_base = bouton.get_theme_stylebox("normal")
	bouton.pressed.connect(func(): selectionnee.emit(_creature_id))
	_pressed_connecte = true
