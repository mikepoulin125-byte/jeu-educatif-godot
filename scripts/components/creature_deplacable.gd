class_name CreatureDeplacable
extends Control
## Creature glissable (glisser-depose) utilisee par le widget
## plan_cartesien (tableaux "placer_point", badge 4) : l'enfant la fait
## glisser jusqu'a l'intersection voulue du plan, ou clique dessus pour
## la SELECTIONNER puis clique l'intersection voulue (voir
## widget_plan_cartesien.gd) - utile des qu'il y a plusieurs creatures a
## placer sur le meme plan (tableau 5+), pour savoir laquelle un clic
## d'intersection doit deplacer. La zone de depot reelle (le plan) gere
## _can_drop_data()/_drop_data() elle-meme (zone_depot_plan_cartesien.gd) -
## ce script ne s'occupe que du cote "source" du glisser-depose.
##
## Instancie dynamiquement (une fois par creature a placer) par le
## widget plutot que fige dans sa scene, pour supporter n'importe quel
## nombre de creatures sans dupliquer de noeuds. configurer() resout ses
## propres enfants via %Nom des l'instantiation, meme reflexe que les
## autres composants de ce projet (voir carte_creature.gd).

signal selectionnee

## Identifiant arbitraire (indice dans la liste de creatures a placer)
## que le widget utilise pour savoir laquelle deplacer lors d'un clic
## d'intersection ou d'un glisser-depose - pas utilise par ce script
## lui-meme, juste transporte.
var index: int = -1

func configurer(sprite_id: String) -> void:
	var texture_sprite: TextureRectAnime = %TextureSprite
	var placeholder: ColorRect = %PlaceholderSprite
	var texture := SpriteUtil.charger_texture(sprite_id)
	if texture != null:
		texture_sprite.configurer_animation(texture, SpriteUtil.compter_frames(texture))
		texture_sprite.visible = true
		placeholder.visible = false
	else:
		texture_sprite.visible = false
		placeholder.visible = true

## set_drag_preview() n'est testable qu'en conditions reelles (exige un
## vrai geste de glisser-depose en cours), donc la charge utile
## transportee est une fonction pure separee, testable seule (meme
## reflexe que berry_item.gd).
func construire_charge_utile() -> Dictionary:
	return {"type": "creature_plan_cartesien", "index": index}

func _get_drag_data(_at_position: Vector2) -> Variant:
	var texture_sprite: TextureRect = %TextureSprite
	var apercu: Control
	if texture_sprite.visible and texture_sprite.texture != null:
		var image := TextureRect.new()
		image.custom_minimum_size = size
		image.size = size
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture = texture_sprite.texture
		apercu = image
	else:
		var rect := ColorRect.new()
		rect.custom_minimum_size = size
		rect.size = size
		rect.color = Color(0.6, 0.6, 0.6, 1.0)
		apercu = rect
	set_drag_preview(apercu)
	selectionnee.emit()
	return construire_charge_utile()

## Un clic simple (sans glisser) SELECTIONNE cette creature - utile pour
## choisir laquelle deplacer par un clic d'intersection ensuite. Un
## glisser-depose selectionne aussi (voir _get_drag_data()) puisqu'il
## commence toujours par le meme evenement de clic.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selectionnee.emit()
