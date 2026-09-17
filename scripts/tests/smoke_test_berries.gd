extends SceneTree
## Test de fumee headless pour le systeme de berries + mecaniques
## "feel good" du Roster (surnom, inventaire, affection/glow, drag and
## drop). Pas execute en jeu normal. Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_berries.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test berries / feel-good Roster ===")

	var SaveManager = preload("res://scripts/autoload/save_manager.gd").new()
	var creature_test := "creature_01"
	SaveManager.delete_save()
	SaveManager.new_game(creature_test)

	# 1. Surnom : vide par defaut, se definit et se sauvegarde.
	if not _verifier(SaveManager.get_surnom_creature(creature_test) == "", "surnom devrait etre vide par defaut"):
		return
	SaveManager.definir_surnom_creature(creature_test, "  Bubulle  ")
	if not _verifier(SaveManager.get_surnom_creature(creature_test) == "Bubulle", "surnom devrait etre 'Bubulle' (espaces retires)"):
		return
	print("OK: surnom defini et nettoie (strip_edges)")

	# 2. Inventaire de berries : vide au depart, ajout/consommation.
	if not _verifier(SaveManager.get_berries_inventaire().is_empty(), "inventaire de berries devrait etre vide au depart"):
		return
	var skin_ajoute := SaveManager.ajouter_berry(5)
	if not _verifier(skin_ajoute == 5, "ajouter_berry(5) devrait retourner 5"):
		return
	if not _verifier(SaveManager.get_berries_inventaire() == [5], "inventaire attendu [5]"):
		return
	SaveManager.ajouter_berry(9)
	if not _verifier(SaveManager.get_berries_inventaire() == [5, 9], "inventaire attendu [5, 9]"):
		return
	if not _verifier(not SaveManager.consommer_berry(99), "consommer_berry(99) hors bornes devrait echouer"):
		return
	if not _verifier(SaveManager.consommer_berry(0), "consommer_berry(0) devrait reussir"):
		return
	if not _verifier(SaveManager.get_berries_inventaire() == [9], "inventaire attendu [9] apres consommation de l'index 0"):
		return
	print("OK: inventaire de berries (ajout/consommation/bornes)")

	# 3. Affection et seuil glow.
	if not _verifier(SaveManager.get_affection_creature(creature_test) == 0, "affection initiale attendue 0"):
		return
	if not _verifier(not SaveManager.est_glow_creature(creature_test), "ne devrait pas etre glow au depart"):
		return
	for i in range(SaveManager.SEUIL_GLOW - 1):
		SaveManager.donner_berry_a_creature(creature_test)
	if not _verifier(SaveManager.get_affection_creature(creature_test) == SaveManager.SEUIL_GLOW - 1, "affection attendue SEUIL_GLOW-1"):
		return
	if not _verifier(not SaveManager.est_glow_creature(creature_test), "pas encore glow a SEUIL_GLOW-1"):
		return
	SaveManager.donner_berry_a_creature(creature_test)
	if not _verifier(SaveManager.est_glow_creature(creature_test), "devrait etre glow a SEUIL_GLOW berries"):
		return
	print("OK: affection cumulee et deblocage glow au seuil de %d berries" % SaveManager.SEUIL_GLOW)

	# 4. Persistance complete apres reload.
	SaveManager.data = {}
	if not _verifier(SaveManager.load_game(), "echec du rechargement de la sauvegarde"):
		return
	if not _verifier(SaveManager.get_surnom_creature(creature_test) == "Bubulle", "surnom devrait persister"):
		return
	if not _verifier(SaveManager.get_berries_inventaire() == [9], "inventaire devrait persister, obtenu: %s" % str(SaveManager.get_berries_inventaire())):
		return
	if not _verifier(SaveManager.est_glow_creature(creature_test), "etat glow devrait persister"):
		return
	print("OK: surnom, inventaire et affection persistent apres sauvegarde/rechargement")

	SaveManager.delete_save()

	# 5. BerryAssetUtil : chemins et couleurs distinctes par skin.
	if not _verifier(BerryAssetUtil.chemin_skin(3) == "res://assets/ui/berries/berry3.png", "chemin de skin incorrect"):
		return
	var couleur1 := BerryAssetUtil.couleur_placeholder(1)
	var couleur6 := BerryAssetUtil.couleur_placeholder(6)
	if not _verifier(not couleur1.is_equal_approx(couleur6), "les couleurs placeholder de skins differents devraient differer"):
		return
	for _i in range(20):
		var skin := BerryAssetUtil.skin_aleatoire()
		if not _verifier(skin >= 1 and skin <= 10, "skin_aleatoire() hors bornes: %d" % skin):
			return
	print("OK: BerryAssetUtil (chemins, couleurs distinctes, tirage dans les bornes)")

	# 6. SpriteUtil : resolution glow avec repli sur le sprite normal.
	if not _verifier(SpriteUtil.id_glow("c1") == "c1_glow", "id_glow('c1') devrait etre 'c1_glow'"):
		return
	if not _verifier(SpriteUtil.glow_manquant("c1", true), "le fichier c1_glow.png ne devrait pas exister (placeholder attendu)"):
		return
	if not _verifier(not SpriteUtil.glow_manquant("c1", false), "glow_manquant devrait etre faux quand le glow n'est pas demande"):
		return
	print("OK: SpriteUtil - resolution glow avec repli propre (aucun asset requis)")

	# 7. BerryItem : configurer() sans crash, _get_drag_data renvoie le bon payload.
	var BerryItemScene := preload("res://scenes/components/BerryItem.tscn")
	var item = BerryItemScene.instantiate()
	root.add_child(item)
	item.configurer(2, 7)
	var payload = item.construire_charge_utile()
	if not _verifier(payload is Dictionary and payload.get("type") == "berry" and payload.get("index_inventaire") == 2 and payload.get("skin") == 7, "payload de drag incorrect: %s" % str(payload)):
		return
	root.remove_child(item)
	item.free()
	print("OK: BerryItem.configurer() et construire_charge_utile() corrects")

	# 8. ZoneDropCreature : accepte uniquement les donnees de type "berry", relaie via signal.
	var ZoneDropScene := preload("res://scripts/components/zone_drop_creature.gd")
	var zone = Control.new()
	zone.set_script(ZoneDropScene)
	root.add_child(zone)
	if not _verifier(zone._can_drop_data(Vector2.ZERO, {"type": "berry"}), "devrait accepter le type 'berry'"):
		return
	if not _verifier(not zone._can_drop_data(Vector2.ZERO, {"type": "autre_chose"}), "ne devrait pas accepter un autre type"):
		return
	if not _verifier(not zone._can_drop_data(Vector2.ZERO, "pas_un_dictionnaire"), "ne devrait pas accepter une donnee non-Dictionary"):
		return
	var signal_recu := {"valeur": null}
	zone.berry_deposee.connect(func(donnees): signal_recu["valeur"] = donnees)
	zone._drop_data(Vector2.ZERO, {"type": "berry", "index_inventaire": 4, "skin": 2})
	if not _verifier(signal_recu["valeur"] != null and signal_recu["valeur"].get("index_inventaire") == 4, "le signal berry_deposee devrait relayer les donnees"):
		return
	root.remove_child(zone)
	zone.free()
	print("OK: ZoneDropCreature filtre correctement et relaie via signal")

	SaveManager.free()
	print("=== Smoke test berries / feel-good Roster : SUCCES ===")
	quit(0)
