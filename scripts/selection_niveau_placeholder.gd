extends Control
## Placeholder Phase 5 : confirme juste que la navigation depuis le Hub
## fonctionne et affiche quelle matiere a ete choisie (GameState.matiere_courante_id).
## A remplacer par le vrai ecran de 10 niveaux (section 8 de la spec).

@onready var label_info: Label = %LabelInfo
@onready var bouton_retour: Button = %BoutonRetour

func _ready() -> void:
	var matiere := DataManager.get_matiere_by_id(GameState.matiere_courante_id)
	var nom: String = String(matiere.get("nom", GameState.matiere_courante_id))
	label_info.text = "Selection de niveau pour : %s\n(ecran a construire en Phase 5)" % nom
	bouton_retour.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Hub.tscn"))
