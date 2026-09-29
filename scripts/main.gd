extends Node
## Point d'entree : lance directement l'ecran titre.

func _ready() -> void:
	SceneTransition.changer_scene.call_deferred("res://scenes/MenuPrincipal.tscn")
