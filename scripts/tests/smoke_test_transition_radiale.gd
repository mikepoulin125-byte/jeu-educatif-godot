extends SceneTree
## Test de fumee headless pour la transition radiale blanche (fondu vers/
## depuis le blanc, bords/centre en premier selon le sens). Pas execute
## en jeu normal. Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_transition_radiale.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test transition radiale ===")

	var TransitionScene := preload("res://scenes/components/TransitionRadiale.tscn")
	var voile = TransitionScene.instantiate()
	root.add_child(voile)

	# 1. definir_progression() doit ecrire directement le parametre du shader
	# (pas besoin d'attendre _ready(), voir le reflexe documente en Phase 3
	# : ce composant n'utilise aucun @onready, il agit directement sur
	# `material`/`size`, disponibles des l'instanciation).
	voile.definir_progression(0.35)
	var valeur: float = voile.material.get_shader_parameter("progression")
	if not _verifier(is_equal_approx(valeur, 0.35), "definir_progression(0.35) - obtenu %f" % valeur):
		return
	print("OK: definir_progression() ecrit bien le parametre du shader")

	# 2. animer() doit interpoler jusqu'a la valeur cible (teste avec une
	# duree courte pour que le test reste rapide).
	await voile.animer(0.0, 1.0, 0.05)
	var valeur_finale: float = voile.material.get_shader_parameter("progression")
	if not _verifier(is_equal_approx(valeur_finale, 1.0), "animer(0.0, 1.0, 0.05) - valeur finale attendue 1.0, obtenu %f" % valeur_finale):
		return
	print("OK: animer() interpole bien jusqu'a la valeur cible (0.0 -> 1.0)")

	await voile.animer(1.0, 0.0, 0.05)
	valeur_finale = voile.material.get_shader_parameter("progression")
	if not _verifier(is_equal_approx(valeur_finale, 0.0), "animer(1.0, 0.0, 0.05) - valeur finale attendue 0.0, obtenu %f" % valeur_finale):
		return
	print("OK: animer() fonctionne aussi dans l'autre sens (1.0 -> 0.0)")

	root.remove_child(voile)
	voile.free()

	# 3. Verifie que les 3 scenes concernees ont bien un noeud de
	# transition (structure statique, independante du script racine qui
	# ne compile pas sous --script pour les scenes referencant un
	# autoload — voir smoke_test_raffinements_menu.gd pour le detail de
	# cette limite documentee).
	var verifications := [
		["res://scenes/MenuPrincipal.tscn", "%FadeBlanc"],
		["res://scenes/DialogueIntro.tscn", "%VoileEntree"],
		["res://scenes/Hub.tscn", "%VoileEntree"],
	]
	for v in verifications:
		var chemin_scene: String = v[0]
		var nom_noeud: String = v[1]
		var scene = load(chemin_scene).instantiate()
		root.add_child(scene)
		var noeud = scene.get_node_or_null(nom_noeud)
		var ok := _verifier(noeud != null, "%s : noeud %s manquant" % [chemin_scene, nom_noeud])
		root.remove_child(scene)
		scene.free()
		if not ok:
			return
	print("OK: MenuPrincipal, DialogueIntro et Hub ont chacun leur noeud de transition radiale")

	print("=== Smoke test transition radiale : SUCCES ===")
	quit(0)
