extends Node
## Point d'entree : lance directement l'ecran titre.

func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/MenuPrincipal.tscn")
