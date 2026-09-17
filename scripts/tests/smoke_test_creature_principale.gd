extends SceneTree
## Test de fumee headless pour la "creature principale" (bouton
## "Accompagne-moi !" du Roster, affichee dans les scenes de tableau).
## Pas execute en jeu normal. Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_creature_principale.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test creature principale ===")

	var SaveManager = preload("res://scripts/autoload/save_manager.gd").new()
	SaveManager.delete_save()
	SaveManager.new_game("creature_01")

	# 1. Repli par defaut (aucun choix explicite) : le starter.
	if not _verifier(SaveManager.get_creature_principale_id() == "creature_01", "repli par defaut devrait etre le starter"):
		return
	print("OK: repli par defaut sur le starter tant qu'aucun choix explicite")

	# 2. Choisir une autre creature capturee comme principale.
	SaveManager.capturer_creature("creature_02")
	# Verifie que capturer_creature() sauvegarde bien (bug trouve par la
	# verification visuelle : la fonction mutait "data" sans jamais
	# appeler save_game(), contrairement a toutes les autres methodes
	# mutatives de ce fichier - corrige).
	SaveManager.data = {}
	if not _verifier(SaveManager.load_game(), "echec du rechargement apres capturer_creature()"):
		return
	if not _verifier(SaveManager.get_creatures_capturees().has("creature_02"), "capturer_creature() devrait persister sur disque"):
		return
	print("OK: capturer_creature() sauvegarde bien sur disque")

	SaveManager.definir_creature_principale("creature_02")
	if not _verifier(SaveManager.get_creature_principale_id() == "creature_02", "creature principale devrait etre creature_02 apres le choix"):
		return
	print("OK: definir_creature_principale() change bien la creature principale")

	# 3. Refus silencieux si la creature n'est pas capturee.
	SaveManager.definir_creature_principale("creature_jamais_capturee")
	if not _verifier(SaveManager.get_creature_principale_id() == "creature_02", "une creature non capturee ne devrait pas devenir principale"):
		return
	print("OK: refus silencieux pour une creature non capturee")

	# 4. Persistance apres reload.
	SaveManager.data = {}
	if not _verifier(SaveManager.load_game(), "echec du rechargement de la sauvegarde"):
		return
	if not _verifier(SaveManager.get_creature_principale_id() == "creature_02", "la creature principale devrait persister apres reload"):
		return
	print("OK: la creature principale persiste apres sauvegarde/rechargement")

	# 5. Repli si la creature principale sauvegardee n'existe plus dans
	# creatures_capturees (garde-fou : ne devrait jamais planter).
	var capturees: Dictionary = SaveManager.get_creatures_capturees()
	capturees.erase("creature_02")
	SaveManager.data["creatures_capturees"] = capturees
	if not _verifier(SaveManager.get_creature_principale_id() == "creature_01", "repli sur le starter si la principale sauvegardee n'est plus capturee"):
		return
	print("OK: repli propre si la creature principale enregistree n'est plus valide")

	SaveManager.delete_save()

	# 6. CarteCreatureRoster : le badge "★" bascule sans erreur.
	var CarteCreatureRosterScene := preload("res://scenes/components/CarteCreatureRoster.tscn")
	var carte = CarteCreatureRosterScene.instantiate()
	root.add_child(carte)
	carte.definir_principale(true)
	var badge: Label = carte.get_node("%LabelBadgePrincipale")
	if not _verifier(badge.visible, "le badge devrait etre visible apres definir_principale(true)"):
		return
	carte.definir_principale(false)
	if not _verifier(not badge.visible, "le badge devrait etre cache apres definir_principale(false)"):
		return
	root.remove_child(carte)
	carte.free()
	print("OK: CarteCreatureRoster.definir_principale() bascule le badge correctement")

	# 7. Structure : Roster.tscn a bien le bouton, EcranTableau.tscn a
	# bien le label de nom du joueur (scripts racines non compiles sous
	# --script, meme limite documentee depuis la Phase 2).
	var RosterScene := preload("res://scenes/Roster.tscn")
	var roster = RosterScene.instantiate()
	root.add_child(roster)
	if not _verifier(roster.get_node_or_null("%BoutonPrincipale") != null, "BoutonPrincipale manquant dans Roster.tscn"):
		return
	root.remove_child(roster)
	roster.free()

	var EcranTableauScene := preload("res://scenes/EcranTableau.tscn")
	var ecran = EcranTableauScene.instantiate()
	root.add_child(ecran)
	if not _verifier(ecran.get_node_or_null("%LabelNomJoueur") != null, "LabelNomJoueur manquant dans EcranTableau.tscn"):
		return
	root.remove_child(ecran)
	ecran.free()
	print("OK: structure de Roster.tscn et EcranTableau.tscn completee pour la creature principale")

	SaveManager.free()
	print("=== Smoke test creature principale : SUCCES ===")
	quit(0)
