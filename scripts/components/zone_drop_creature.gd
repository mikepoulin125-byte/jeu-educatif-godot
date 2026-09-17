extends Control
class_name ZoneDropCreature
## Cible de glisser-deposer generique : accepte les donnees de type
## "berry" (voir berry_item.gd) et relaie l'evenement via un signal,
## pour que la logique de jeu reste dans roster.gd plutot que dispersee
## dans un script de composant.

signal berry_deposee(donnees: Dictionary)

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "berry"

func _drop_data(_at_position: Vector2, data) -> void:
	berry_deposee.emit(data)
