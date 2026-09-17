extends SceneTree
## Test de fumee headless : le hub (8 badges de matiere + bouton Roster)
## reprend bien le meme langage visuel que le menu principal (bordure
## #CC0000, script BoutonAnime), en plus des verifications structurelles
## deja faites par smoke_test_phase3.gd. Pas execute en jeu normal.
## Lance avec : godot --headless --script res://scripts/tests/smoke_test_hub_style.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test style du hub (bordure/anim) ===")

	var couleur_attendue := Color(0.8, 0, 0, 1)  # #CC0000

	# 1. CarteMatiere : bordure #CC0000 sur les 3 etats du bouton circulaire.
	var CarteMatiereScene := preload("res://scenes/components/CarteMatiere.tscn")
	var carte = CarteMatiereScene.instantiate()
	root.add_child(carte)
	var bouton_cercle: Button = carte.get_node("%BoutonCercle")
	for etat in ["normal", "hover", "pressed"]:
		var style: StyleBoxFlat = bouton_cercle.get_theme_stylebox(etat)
		if not _verifier(style.border_color.is_equal_approx(couleur_attendue), "CarteMatiere/%s : bordure attendue #CC0000, obtenu %s" % [etat, style.border_color]):
			return
	root.remove_child(carte)
	carte.free()
	print("OK: CarteMatiere a la bordure #CC0000 sur ses 3 etats")

	# 2. Hub : bouton Roster avec bordure #CC0000, XP et bouton Roster presents.
	var HubScene := preload("res://scenes/Hub.tscn")
	var hub = HubScene.instantiate()
	root.add_child(hub)

	var label_xp = hub.get_node_or_null("%LabelXp")
	var bouton_roster: Button = hub.get_node_or_null("%BoutonRoster")
	if not _verifier(label_xp != null, "LabelXp introuvable dans Hub.tscn"):
		return
	if not _verifier(bouton_roster != null, "BoutonRoster introuvable dans Hub.tscn"):
		return

	var style_roster: StyleBoxFlat = bouton_roster.get_theme_stylebox("normal")
	if not _verifier(style_roster.border_color.is_equal_approx(couleur_attendue), "BoutonRoster : bordure attendue #CC0000, obtenu %s" % style_roster.border_color):
		return
	print("OK: LabelXp et BoutonRoster presents, BoutonRoster a la bordure #CC0000")

	var grille = hub.get_node_or_null("%GrilleMatieres")
	if not _verifier(grille != null, "GrilleMatieres introuvable dans Hub.tscn"):
		return
	print("OK: GrilleMatieres presente (accueil des 8 badges de matiere)")

	root.remove_child(hub)
	hub.free()

	print("=== Smoke test style du hub : SUCCES ===")
	quit(0)
