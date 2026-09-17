extends SceneTree
## Test de fumee headless pour les raffinements du menu principal :
## bordure rouge des boutons, script d'animation, son de clic silencieux
## par defaut, et les formules pures de l'ecran de chargement (rotation
## + rebond des points). Pas execute en jeu normal.
## Lance avec : godot --headless --script res://scripts/tests/smoke_test_raffinements_menu.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

const TOLERANCE := 0.0001

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _proche(a: float, b: float, tolerance: float = TOLERANCE) -> bool:
	return abs(a - b) < tolerance

## Distance angulaire la plus courte entre deux angles (gere le
## rebouclage a TAU), pour comparer des rotations sans faux echec du a
## l'imprecision flottante pile a la frontiere 0/TAU.
func _distance_angulaire(a: float, b: float) -> float:
	var diff := fmod(abs(a - b), TAU)
	return min(diff, TAU - diff)

func _initialize() -> void:
	print("=== Smoke test raffinements menu (bordure/anim/son/chargement) ===")

	# 1. AnimMathUtil : rotation (2s = 1 tour complet).
	if not _verifier(_distance_angulaire(AnimMathUtil.rotation_apres(0.0), 0.0) < TOLERANCE, "rotation_apres(0.0) devrait etre 0"):
		return
	if not _verifier(_distance_angulaire(AnimMathUtil.rotation_apres(1.0), PI) < TOLERANCE, "rotation_apres(1.0) devrait etre PI (demi-tour)"):
		return
	if not _verifier(_distance_angulaire(AnimMathUtil.rotation_apres(2.0), 0.0) < TOLERANCE, "rotation_apres(2.0) devrait boucler a 0 (1 tour complet en 2s)"):
		return
	print("OK: AnimMathUtil.rotation_apres() - 1 tour toutes les 2s")

	# 2. AnimMathUtil : rebond des points, avec decalage de phase de 100ms.
	if not _verifier(_proche(AnimMathUtil.decalage_point_chargement(0.0, 0), 0.0), "decalage_point_chargement(0.0, 0) devrait etre 0"):
		return
	if not _verifier(_proche(AnimMathUtil.decalage_point_chargement(0.15, 0), -8.0), "point 0 devrait etre au sommet du rebond a t=0.15s"):
		return
	if not _verifier(_proche(AnimMathUtil.decalage_point_chargement(0.1, 1), 0.0), "point 1 (decale de 100ms) devrait etre a son point de depart a t=0.1s (phase=0 pour lui, comme le point 0 a t=0.0s)"):
		return
	if not _verifier(_proche(AnimMathUtil.decalage_point_chargement(0.25, 1), -8.0), "point 1 devrait etre au sommet du rebond a t=0.25s (0.15s apres son decalage de 100ms)"):
		return
	print("OK: AnimMathUtil.decalage_point_chargement() - effet de vague entre les 3 points")

	# 3. AudioManager : silencieux tant qu'aucun son n'est depose (pas de crash).
	var AudioManagerScript := preload("res://scripts/autoload/audio_manager.gd")
	var audio_manager = AudioManagerScript.new()
	audio_manager._ready()
	if not _verifier(audio_manager._son_clic == null, "aucun son de clic ne devrait etre charge (assets/audio/ui/clic_bouton.* absent)"):
		return
	audio_manager.jouer_clic()  # ne doit pas planter
	audio_manager.free()
	print("OK: AudioManager silencieux et sans erreur en l'absence de clic_bouton.*")

	# 4. MenuPrincipal.tscn : bordure rouge #CC0000 sur les 3 boutons.
	# Note : on ne peut PAS verifier ici que le script BoutonAnime est
	# attache (bouton.get_script()) : ce script reference l'autoload
	# AudioManager, qui ne compile pas sous --script (meme piege que
	# SaveManager/DataManager/GameState documente en Phase 2/3 et pour
	# menu_principal.gd/ecran_chargement.gd ci-dessus) — quand un script
	# ne compile pas, Godot n'attache tout simplement pas de script au
	# noeud instancie (get_script() renvoie null), donc l'egalite de
	# resource echouerait ici alors que tout fonctionne correctement en
	# jeu reel (confirme par le boot headless reel, autoloads charges).
	var MenuScene := preload("res://scenes/MenuPrincipal.tscn")
	var menu = MenuScene.instantiate()
	root.add_child(menu)

	var couleur_attendue := Color(0.8, 0, 0, 1)  # #CC0000
	for nom_bouton in ["%BoutonNouvellePartie", "%BoutonContinuer", "%BoutonQuitter"]:
		var bouton: Button = menu.get_node(nom_bouton)
		var style: StyleBoxFlat = bouton.get_theme_stylebox("normal")
		if not _verifier(style.border_color.is_equal_approx(couleur_attendue), "%s : bordure attendue #CC0000, obtenu %s" % [nom_bouton, style.border_color]):
			return
	print("OK: les 3 boutons ont la bordure #CC0000")

	var fade_blanc: ColorRect = menu.get_node("%FadeBlanc")
	if not _verifier(fade_blanc.color.a < TOLERANCE, "FadeBlanc devrait demarrer invisible (alpha 0)"):
		return
	print("OK: FadeBlanc demarre invisible")

	root.remove_child(menu)
	menu.free()

	# 5. EcranChargement.tscn : structure attendue presente.
	var ChargementScene := preload("res://scenes/EcranChargement.tscn")
	var chargement = ChargementScene.instantiate()
	root.add_child(chargement)

	var noeuds_attendus := ["%ZoneRotation", "%TextureIcone", "%PlaceholderIcone", "%Point0", "%Point1", "%Point2", "%Timer"]
	for chemin in noeuds_attendus:
		if not _verifier(chargement.get_node_or_null(chemin) != null, "noeud manquant dans EcranChargement.tscn: " + chemin):
			return
	print("OK: structure de EcranChargement.tscn complete (rotation, placeholders, 3 points, timer)")

	root.remove_child(chargement)
	chargement.free()

	print("=== Smoke test raffinements menu : SUCCES ===")
	quit(0)
