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
	var couleur_blanche := Color(1, 1, 1, 1)

	# 1. CarteMatiere : contour BLANC (exterieur, sur le bouton -- change
	# depuis rouge sur demande de Mike) sur les 3 etats du bouton
	# circulaire, fond brun/beige pale, et anneau NOIR distinct juste a
	# l'interieur (AnneauNoir, contour double blanc+noir).
	var CarteMatiereScene := preload("res://scenes/components/CarteMatiere.tscn")
	var carte = CarteMatiereScene.instantiate()
	root.add_child(carte)
	var bouton_cercle: Button = carte.get_node("%BoutonCercle")
	for etat in ["normal", "hover", "pressed"]:
		var style: StyleBoxFlat = bouton_cercle.get_theme_stylebox(etat)
		if not _verifier(style.border_color.is_equal_approx(couleur_blanche), "CarteMatiere/%s : bordure attendue blanche, obtenu %s" % [etat, style.border_color]):
			return
		if not _verifier(not style.bg_color.is_equal_approx(couleur_blanche), "CarteMatiere/%s : le fond ne devrait plus etre blanc (beige attendu)" % etat):
			return
	var anneau: Panel = carte.get_node("%AnneauNoir")
	var style_anneau: StyleBoxFlat = anneau.get_theme_stylebox("panel")
	if not _verifier(style_anneau.border_color.is_equal_approx(Color(0, 0, 0, 1)), "AnneauNoir : contour attendu noir, obtenu %s" % style_anneau.border_color):
		return
	root.remove_child(carte)
	carte.free()
	print("OK: CarteMatiere - contour double blanc (exterieur) + noir (AnneauNoir, interieur), fond beige")

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

	# 3. Titre change sur demande de Mike : "Choisis une matiere" ->
	# "Choisis un badge".
	var label_titre: Label = hub.get_node_or_null("CentreTitre/BanniereTitre/LabelTitre")
	if not _verifier(label_titre != null, "LabelTitre introuvable dans Hub.tscn"):
		return
	if not _verifier(label_titre.text == "Choisis un badge", "titre attendu 'Choisis un badge', obtenu '%s'" % label_titre.text):
		return
	print("OK: titre du Hub change en 'Choisis un badge'")

	# 4. ZoneGauche reduite de 50%% (440x680 -> 220x340) et ZoneDroite
	# reduite de 60%% (220x340 -> 88x136), repositionnee juste a cote de
	# ZoneGauche (demande de Mike).
	var zone_gauche: Control = hub.get_node_or_null("ZoneGauche")
	var zone_droite: Control = hub.get_node_or_null("ZoneDroite")
	if not _verifier(zone_gauche != null and zone_droite != null, "ZoneGauche/ZoneDroite introuvables dans Hub.tscn"):
		return
	var taille_gauche := Vector2(zone_gauche.offset_right - zone_gauche.offset_left, zone_gauche.offset_bottom - zone_gauche.offset_top)
	var taille_droite := Vector2(zone_droite.offset_right - zone_droite.offset_left, zone_droite.offset_bottom - zone_droite.offset_top)
	if not _verifier(taille_gauche.is_equal_approx(Vector2(220, 340)), "ZoneGauche devrait faire 220x340 (reduite de 50%%), obtenu %s" % taille_gauche):
		return
	if not _verifier(taille_droite.is_equal_approx(Vector2(88, 136)), "ZoneDroite devrait faire 88x136 (reduite de 60%%), obtenu %s" % taille_droite):
		return
	if not _verifier(zone_droite.offset_left < zone_gauche.offset_right + 50, "ZoneDroite devrait etre juste a cote de ZoneGauche, pas loin a droite de l'ecran"):
		return
	print("OK: ZoneGauche (-50%%) et ZoneDroite (-60%%, repositionnee a cote) aux bonnes tailles")

	root.remove_child(hub)
	hub.free()

	print("=== Smoke test style du hub : SUCCES ===")
	quit(0)
