extends Control
## Placeholder Phase 4 : confirme que le bouton Roster du Hub fonctionne.
## A remplacer par le vrai ecran de gestion des creatures (section 7 de la spec).

@onready var bouton_retour: Button = %BoutonRetour

func _ready() -> void:
	bouton_retour.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Hub.tscn"))
