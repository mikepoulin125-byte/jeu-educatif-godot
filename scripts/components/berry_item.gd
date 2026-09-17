extends Control
class_name BerryItem
## Icone de berry dans l'inventaire du Roster, draggable (glisser-deposer
## sur une creature). configurer() resout les noeuds enfants via %Nom a
## chaque appel (fonctionne des instantiate(), meme reflexe que les
## autres composants de ce projet).

var index_inventaire: int = -1
var skin: int = 1

func configurer(index: int, skin_valeur: int) -> void:
	index_inventaire = index
	skin = skin_valeur

	var texture_berry: TextureRect = %TextureBerry
	var placeholder: Panel = %PlaceholderBerry

	var texture := BerryAssetUtil.charger_texture(skin)
	if texture != null:
		texture_berry.texture = texture
		texture_berry.visible = true
		placeholder.visible = false
	else:
		texture_berry.visible = false
		placeholder.visible = true
		var style: StyleBoxFlat = placeholder.get_theme_stylebox("panel").duplicate()
		style.bg_color = BerryAssetUtil.couleur_placeholder(skin)
		placeholder.add_theme_stylebox_override("panel", style)

	tooltip_text = "Berry #%d" % skin

## Donnees transportees par le glisser-depose. Fonction pure separee de
## _get_drag_data() pour rester testable sans avoir besoin d'un Viewport
## reel actif (set_drag_preview() exige d'etre appelee pendant un vrai
## geste de glisser-depose, donc pas testable directement en headless).
func construire_charge_utile() -> Dictionary:
	return {"type": "berry", "index_inventaire": index_inventaire, "skin": skin}

func _get_drag_data(_at_position: Vector2) -> Variant:
	var texture_berry: TextureRect = %TextureBerry
	if texture_berry.visible and texture_berry.texture != null:
		var apercu := TextureRect.new()
		apercu.custom_minimum_size = Vector2(56, 56)
		apercu.size = Vector2(56, 56)
		apercu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		apercu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		apercu.texture = texture_berry.texture
		set_drag_preview(apercu)
	else:
		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(56, 56)
		rect.size = Vector2(56, 56)
		rect.color = BerryAssetUtil.couleur_placeholder(skin)
		set_drag_preview(rect)
	return construire_charge_utile()
