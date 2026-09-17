extends Control
## Ecran temporaire de Phase 1 : confirme que le chargement JSON et la
## sauvegarde fonctionnent de bout en bout. Sera remplace par l'intro
## (Phase 2) et le hub (Phase 3).

@onready var label_info: Label = %LabelInfo
@onready var bouton_retour: Button = %BoutonRetour

func _ready() -> void:
	bouton_retour.pressed.connect(_on_retour)
	_afficher_etat()

func _afficher_etat() -> void:
	var lignes := []
	lignes.append("--- Sauvegarde (SaveManager) ---")
	lignes.append("XP total: %d" % SaveManager.get_xp_total())
	lignes.append("Starter: %s" % str(SaveManager.data.get("starter_id", "")))
	lignes.append("Creatures vues: %s" % str(SaveManager.get_creatures_vues()))
	lignes.append("")
	lignes.append("--- Donnees (DataManager) ---")
	lignes.append("Creatures chargees: %d" % DataManager.creatures.size())
	lignes.append("Matieres chargees: %d" % DataManager.matieres.size())
	lignes.append("Types charges: %d" % DataManager.types.size())
	label_info.text = "\n".join(lignes)

func _on_retour() -> void:
	get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")
