extends SceneTree
## Test de fumee headless pour la Phase 4 (Roster et evolutions). Pas
## execute en jeu normal. Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_phase4.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test Phase 4 (Roster et evolutions) ===")

	var DataManager = preload("res://scripts/autoload/data_manager.gd").new()
	DataManager.reload_all()
	var SaveManager = preload("res://scripts/autoload/save_manager.gd").new()

	# 0. creature_01 (placeholder) a 3 stades - verifie l'hypothese de depart du test.
	var creature_test := "creature_01"
	if not _verifier(int(DataManager.creatures[creature_test].get("stages", 0)) == 3, "creature_01 devrait avoir 3 stades dans le placeholder de creatures.json"):
		return

	# 1. cout_evolution_vers().
	if not _verifier(SaveManager.cout_evolution_vers(2) == 300, "cout vers stade 2 devrait etre 300"):
		return
	if not _verifier(SaveManager.cout_evolution_vers(3) == 500, "cout vers stade 3 devrait etre 500"):
		return
	if not _verifier(SaveManager.cout_evolution_vers(1) == -1, "cout vers stade 1 devrait etre invalide (-1)"):
		return
	if not _verifier(SaveManager.cout_evolution_vers(4) == -1, "cout vers stade 4 devrait etre invalide (-1)"):
		return
	print("OK: cout_evolution_vers() - 300 pour le stade 2, 500 pour le stade 3, invalide sinon")

	# 2. Nouvelle partie, la creature de depart est au stade 1.
	SaveManager.delete_save()
	SaveManager.new_game(creature_test)
	if not _verifier(SaveManager.get_stage_creature(creature_test) == 1, "stade initial attendu 1"):
		return

	# 3. Evolution refusee si XP insuffisant (0 XP disponible).
	var reussi := SaveManager.faire_evoluer_creature(creature_test)
	if not _verifier(not reussi, "l'evolution devrait echouer sans XP"):
		return
	if not _verifier(SaveManager.get_stage_creature(creature_test) == 1, "le stade ne devrait pas changer apres un echec"):
		return
	print("OK: faire_evoluer_creature() refuse sans XP suffisant")

	# 4. Evolution vers le stade 2 (300 XP).
	SaveManager.add_xp(300)
	reussi = SaveManager.faire_evoluer_creature(creature_test)
	if not _verifier(reussi, "l'evolution vers le stade 2 devrait reussir avec 300 XP"):
		return
	if not _verifier(SaveManager.get_stage_creature(creature_test) == 2, "stade attendu 2 apres evolution"):
		return
	if not _verifier(SaveManager.get_xp_total() == 0, "XP total attendu 0 apres avoir depense 300"):
		return
	if not _verifier(SaveManager.get_xp_investi_creature(creature_test) == 300, "XP investi attendu 300"):
		return
	print("OK: evolution stade 1 -> 2 (300 XP deduits correctement)")

	# 5. Evolution vers le stade 3 (500 XP).
	SaveManager.add_xp(500)
	reussi = SaveManager.faire_evoluer_creature(creature_test)
	if not _verifier(reussi, "l'evolution vers le stade 3 devrait reussir avec 500 XP"):
		return
	if not _verifier(SaveManager.get_stage_creature(creature_test) == 3, "stade attendu 3 apres evolution"):
		return
	if not _verifier(SaveManager.get_xp_investi_creature(creature_test) == 800, "XP investi cumule attendu 800 (300+500)"):
		return
	print("OK: evolution stade 2 -> 3 (500 XP deduits correctement, cumul XP investi)")

	# 6. Refus au-dela du stade maximal, meme avec beaucoup d'XP.
	SaveManager.add_xp(1000)
	reussi = SaveManager.faire_evoluer_creature(creature_test)
	if not _verifier(not reussi, "l'evolution devrait etre refusee au-dela du stade 3"):
		return
	if not _verifier(SaveManager.get_stage_creature(creature_test) == 3, "le stade devrait rester 3"):
		return
	print("OK: aucune evolution possible au-dela du stade maximal (meme avec beaucoup d'XP)")

	# 7. Persistance : la sauvegarde survit a un reload depuis le disque.
	SaveManager.data = {}
	var charge := SaveManager.load_game()
	if not _verifier(charge, "echec du rechargement de la sauvegarde"):
		return
	if not _verifier(SaveManager.get_stage_creature(creature_test) == 3, "stade 3 devrait persister apres reload"):
		return
	if not _verifier(SaveManager.get_xp_investi_creature(creature_test) == 800, "xp_investi=800 devrait persister apres reload"):
		return
	print("OK: le stade et l'XP investi persistent apres sauvegarde/rechargement")

	SaveManager.delete_save()

	# 8. CarteCreatureRoster : configurer() sans crash, nom applique pour le bon stade.
	var CarteCreatureRosterScene := preload("res://scenes/components/CarteCreatureRoster.tscn")
	var carte = CarteCreatureRosterScene.instantiate()
	root.add_child(carte)
	carte.configurer(creature_test, DataManager.creatures[creature_test], 2)
	var noms: Dictionary = DataManager.creatures[creature_test].get("names", {})
	var nom_attendu: String = String(noms.get("stage2", creature_test))
	var nom_obtenu: String = carte.get_node("%LabelNom").text
	if not _verifier(nom_obtenu == nom_attendu, "CarteCreatureRoster : nom attendu '%s', obtenu '%s'" % [nom_attendu, nom_obtenu]):
		return
	carte.definir_selectionnee(true)
	carte.definir_selectionnee(false)
	root.remove_child(carte)
	carte.free()
	print("OK: CarteCreatureRoster.configurer() et definir_selectionnee() sans erreur")

	# 9. Roster.tscn : structure attendue presente (le script racine ne
	# compile pas sous --script car il reference des autoloads, meme
	# limite documentee depuis la Phase 2 - la structure des noeuds reste
	# verifiable independamment).
	var RosterScene := preload("res://scenes/Roster.tscn")
	var roster = RosterScene.instantiate()
	root.add_child(roster)
	var noeuds_attendus := [
		"%LabelXp", "%BoutonRetour", "%GrilleCreatures",
		"%TextureDetail", "%PlaceholderDetail", "%LineEditSurnom",
		"%LabelStadeDetail", "%BarreXp", "%BarreAffection",
		"%BoutonAttribuerXp", "%LabelStatut", "%ListeBerries"
	]
	for chemin in noeuds_attendus:
		if not _verifier(roster.get_node_or_null(chemin) != null, "noeud manquant dans Roster.tscn: " + chemin):
			return
	root.remove_child(roster)
	roster.free()
	print("OK: structure de Roster.tscn complete")

	DataManager.free()
	SaveManager.free()
	print("=== Smoke test Phase 4 : SUCCES ===")
	quit(0)
