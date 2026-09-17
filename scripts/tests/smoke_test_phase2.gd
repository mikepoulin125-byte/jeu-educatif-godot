extends SceneTree
## Test de fumee headless pour la Phase 2 (pas execute en jeu normal).
## Lance avec : godot --headless --script res://scripts/tests/smoke_test_phase2.gd
## Simule le parcours Menu -> Intro -> Choix starter -> Sauvegarde, sans GUI reelle.

func _initialize() -> void:
	print("=== Smoke test Phase 2 ===")

	# --script bypasse le boot normal des autoloads : on instancie les
	# managers manuellement (les memes scripts que ceux utilises en autoload).
	var DataManager = preload("res://scripts/autoload/data_manager.gd").new()
	DataManager.reload_all()
	var SaveManager = preload("res://scripts/autoload/save_manager.gd").new()

	var CarteCreatureScene := preload("res://scenes/components/CarteCreature.tscn")

	# 1. Verifie que les lignes d'intro se chargent.
	var lignes := DataManager.get_lignes_intro()
	assert(lignes.size() == 4, "attendu 4 lignes d'intro, obtenu %d" % lignes.size())
	print("OK: intro.json charge (%d lignes)" % lignes.size())

	# 2. Verifie les starters.
	var starters := DataManager.get_creatures_starters()
	assert(starters.size() == 3, "attendu 3 starters, obtenu %d" % starters.size())
	print("OK: %d creatures starter trouvees: %s" % [starters.size(), str(starters)])

	# 3. Instancie une carte pour chaque starter (verifie configurer() ne crashe pas).
	for id in starters:
		var carte = CarteCreatureScene.instantiate()
		root.add_child(carte)
		carte.configurer(id, DataManager.creatures[id])
		assert(carte.get_node("%LabelNom").text != "", "nom vide pour " + id)
		root.remove_child(carte)
		carte.free()
	print("OK: cartes de starter configurees sans erreur")

	# 4. Simule le choix d'un starter -> cree la sauvegarde.
	SaveManager.delete_save()
	var choix: String = starters[0]
	SaveManager.new_game(choix)
	assert(SaveManager.data.get("starter_id") == choix, "starter_id non enregistre")
	assert(SaveManager.get_creatures_vues().has(choix), "starter pas dans creatures_vues")
	assert(SaveManager.get_creatures_capturees().has(choix), "starter pas dans creatures_capturees")
	print("OK: SaveManager.new_game('%s') -> sauvegarde correcte" % choix)

	# 5. Verifie que la sauvegarde survit a un reload depuis le disque.
	SaveManager.data = {}
	var charge := SaveManager.load_game()
	assert(charge, "echec du rechargement de la sauvegarde")
	assert(SaveManager.data.get("starter_id") == choix, "starter_id perdu apres reload")
	print("OK: sauvegarde rechargee depuis le disque")

	SaveManager.delete_save()
	DataManager.free()
	SaveManager.free()
	print("=== Smoke test Phase 2 : SUCCES ===")
	quit(0)
