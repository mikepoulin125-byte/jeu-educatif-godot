extends Control
## Ecran de choix du starter : instancie une CarteCreature par creature
## marquee "starter": true dans data/creatures.json.

const CarteCreatureScene := preload("res://scenes/components/CarteCreature.tscn")

@onready var conteneur_cartes: HBoxContainer = %ConteneurCartes
@onready var label_titre: Label = %LabelTitre

func _ready() -> void:
	AudioManager.jouer_musique(AudioManager.MUSIQUE_DEBUT_PARTIE)
	var ids := DataManager.get_creatures_starters()
	if ids.is_empty():
		label_titre.text = "Aucune creature de depart configuree (data/creatures.json)."
		return
	for id in ids:
		var carte := CarteCreatureScene.instantiate()
		conteneur_cartes.add_child(carte)
		carte.configurer(id, DataManager.creatures[id])
		carte.choisie.connect(_on_creature_choisie)

func _on_creature_choisie(creature_id: String) -> void:
	SaveManager.new_game(creature_id)
	SceneTransition.changer_scene("res://scenes/Hub.tscn")
