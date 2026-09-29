class_name CreatureDeplacable
extends Control
## Creature glissable (glisser-depose) utilisee par le widget
## plan_cartesien (tableau "placer_point", badge 4) : l'enfant la fait
## glisser jusqu'a l'intersection voulue du plan, ou clique directement
## l'intersection (voir widget_plan_cartesien.gd) pour la deplacer sans
## glisser-deposer. La zone de depot reelle (le plan) gere
## _can_drop_data()/_drop_data() elle-meme (widget_plan_cartesien.gd) -
## ce script ne s'occupe que du cote "source" du glisser-depose.
##
## set_drag_preview() n'est testable qu'en conditions reelles (exige un
## vrai geste de glisser-depose en cours), donc la charge utile
## transportee est une fonction pure separee, testable seule (meme
## reflexe que berry_item.gd).

func construire_charge_utile() -> Dictionary:
	return {"type": "creature_plan_cartesien"}

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
	return construire_charge_utile()
