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

	# 3. SceneTransition (autoload, Phase 8) : centralise desormais le
	# fondu au blanc pour TOUTES les transitions entre scenes (remplace
	# les anciens noeuds VoileEntree/FadeBlanc par scene). Cree son propre
	# voile partage a _ready(), invisible par defaut (progression=0.0).
	var SceneTransitionScript := preload("res://scripts/autoload/scene_transition.gd")
	var scene_transition = SceneTransitionScript.new()
	scene_transition._ready()
	var voile_partage: TransitionRadiale = scene_transition._voile
	if not _verifier(voile_partage != null, "SceneTransition devrait creer son voile partage des _ready()"):
		return
	var progression_partagee: float = voile_partage.material.get_shader_parameter("progression")
	if not _verifier(is_equal_approx(progression_partagee, 0.0), "le voile de SceneTransition devrait demarrer invisible (progression=0.0), obtenu %f" % progression_partagee):
		return
	scene_transition.free()
	print("OK: SceneTransition cree un voile partage unique, invisible par defaut")

	print("=== Smoke test transition radiale : SUCCES ===")
	quit(0)
