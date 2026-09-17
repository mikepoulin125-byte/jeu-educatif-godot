extends Control

@onready var bouton_nouvelle_partie: Button = %BoutonNouvellePartie
@onready var bouton_continuer: Button = %BoutonContinuer
@onready var bouton_quitter: Button = %BoutonQuitter

func _ready() -> void:
	bouton_continuer.disabled = not SaveManager.has_save()
	bouton_nouvelle_partie.pressed.connect(_on_nouvelle_partie)
	bouton_continuer.pressed.connect(_on_continuer)
	bouton_quitter.pressed.connect(_on_quitter)

func _on_nouvelle_partie() -> void:
	# Phase 2 remplacera ceci par l'intro narrative + choix du starter.
	# Pour l'instant : cree une sauvegarde vierge (aucun starter choisi) et va vers l'ecran de debug.
	SaveManager.new_game("")
	get_tree().change_scene_to_file("res://scenes/DebugEtatSauvegarde.tscn")

func _on_continuer() -> void:
	SaveManager.load_game()
	get_tree().change_scene_to_file("res://scenes/DebugEtatSauvegarde.tscn")

func _on_quitter() -> void:
	get_tree().quit()
