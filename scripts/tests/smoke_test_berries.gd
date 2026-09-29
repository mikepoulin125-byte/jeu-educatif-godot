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
	# Utilise un id bidon (jamais un vrai "cN") : Mike a deja depose
	# beaucoup de vrais sprites/glows en local (c1, c4, c6, c7, c40,
	# c41...), donc "c1" etc. ne sont plus fiables pour un test "fichier
	# absent" — meme situation deja documentee plusieurs fois pour
	# logo_menu.png/gauche.png/clic_bouton.mp3/exam_*_icon.png.
	var id_bidon := "c_bidon_inexistant"
	if not _verifier(SpriteUtil.id_glow(id_bidon) == "c_bidon_inexistant_glow", "id_glow() devrait juste suffixer '_glow'"):
		return
	if not _verifier(SpriteUtil.glow_manquant(id_bidon, true), "le glow d'un id bidon ne devrait jamais exister (placeholder attendu)"):
		return
	if not _verifier(not SpriteUtil.glow_manquant(id_bidon, false), "glow_manquant devrait etre faux quand le glow n'est pas demande"):
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

	# 8. BerryItem : "secousse" (rotation+bounce) puis RETOUR au neutre
	# puis PAUSE silencieuse de 2-4s avant de recommencer (Phase 8,
	# ajustement demande par Mike - avant c'etait une boucle continue
	# sans pause). Declenche _cycle_wobble() directement (sans attendre
	# le delai de depart aleatoire) pour garder le test rapide.
	item = BerryItemScene.instantiate()
	root.add_child(item)
	await process_frame
	# _ready() a deja lance son propre wobble automatique (delai aleatoire
	# 0-0.6s) ; on le neutralise via _survole (bloque _cycle_wobble()) le
	# temps de tester NOTRE appel manuel de facon deterministe, sinon les
	# deux tweens se disputeraient rotation/scale de facon imprevisible.
	item._survole = true
	item.rotation = 0.0
	item.scale = Vector2.ONE
	item._survole = false
	item._cycle_wobble(item)
	item._survole = true  # re-bloque immediatement : evite qu'un auto-demarrage encore en attente ne demarre pendant qu'on observe notre propre cycle
	# 0.3s (pas 0.15s) : avec TRANS_SINE/EASE_IN_OUT, le debut de la
	# courbe est tres plat (progression quasi nulle dans le premier
	# quart), donc un echantillon trop tot + un petit angle/duree tires
	# au hasard pouvait rester indiscernable de 0.0 (flakiness observee).
	# A 0.3s, la progression est significative meme dans le pire cas
	# (duree max 0.6s -> 50% de la 1ere phase).
	await create_timer(0.3).timeout
	if not _verifier(item.rotation != 0.0, "en cours de secousse, la rotation devrait deja avoir bouge"):
		return
	# Duree max d'une secousse complete (aller + retour) = 2 x 0.6s ;
	# on attend un peu plus pour etre certain qu'elle est terminee.
	await create_timer(1.1).timeout
	if not _verifier(is_equal_approx(item.rotation, 0.0), "apres la secousse complete, la rotation devrait etre revenue a 0 (pause)"):
		return
	if not _verifier(item.scale.is_equal_approx(Vector2.ONE), "apres la secousse complete, l'echelle devrait etre revenue a 1 (pause)"):
		return
	# Toujours en pause peu apres (la pause dure au moins 2s) : aucune
	# nouvelle secousse ne devrait avoir demarre entre-temps.
	await create_timer(0.3).timeout
	if not _verifier(is_equal_approx(item.rotation, 0.0), "pendant la pause (min. 2s), aucune nouvelle secousse ne devrait avoir demarre"):
		return
	root.remove_child(item)
	item.free()
	print("OK: BerryItem.wobble - secousse puis retour au neutre puis pause silencieuse avant de recommencer")

	# 9. BerryItem : survol -> agrandissement + decalage vers le haut +
	# z_index rehausse ; interrompt proprement le wobble (pas de conflit
	# d'animation), et revient a la normale (+ relance le wobble) a la
	# sortie du survol.
	item = BerryItemScene.instantiate()
	root.add_child(item)
	await process_frame
	item.position = Vector2(100, 100)
	item._on_survol_entre()
	await create_timer(0.2).timeout
	if not _verifier(item.z_index == 10, "z_index devrait etre rehausse pendant le survol"):
		return
	if not _verifier(item.scale.x > 1.0, "l'echelle devrait etre agrandie pendant le survol"):
		return
	if not _verifier(item.position.y < 100.0, "la berry devrait etre decalee vers le haut pendant le survol"):
		return
	item._on_survol_sort()
	# Re-bloque immediatement _cycle_wobble() pour SELF : evite qu'un
	# auto-demarrage de _ready() encore en attente (delai aleatoire
	# 0-0.6s) ne vienne se disputer scale/rotation avec le tween de
	# sortie de survol pendant qu'on l'observe (meme piege que pour le
	# test du wobble plus haut).
	item._survole = true
	await create_timer(0.2).timeout
	if not _verifier(item.z_index == 0, "z_index devrait revenir a 0 apres le survol"):
		return
	if not _verifier(item.scale.is_equal_approx(Vector2.ONE), "l'echelle devrait revenir a 1 apres le survol"):
		return
	if not _verifier(is_equal_approx(item.position.y, 100.0), "la position devrait revenir a l'origine apres le survol"):
		return
	root.remove_child(item)
	item.free()
	print("OK: BerryItem - le survol agrandit/decale/rehausse le z_index, et revient a la normale a la sortie")

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
