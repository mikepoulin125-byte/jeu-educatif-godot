extends SceneTree
## Test de fumee headless pour la Phase 3 (pas execute en jeu normal).
## Lance avec : godot --headless --script res://scripts/tests/smoke_test_phase3.gd
##
## N'utilise jamais assert() : en GDScript, un assert() qui echoue declenche
## une pause du debugger de script, ce qui bloque indefiniment un run
## --headless sans debugger attache. On verifie et on quitte explicitement a la place.

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test Phase 3 ===")

	var DataManager = preload("res://scripts/autoload/data_manager.gd").new()
	DataManager.reload_all()
	var SaveManager = preload("res://scripts/autoload/save_manager.gd").new()

	# 1. Verifie les 8 matieres.
	if not _verifier(DataManager.matieres.size() == 8, "attendu 8 matieres, obtenu %d" % DataManager.matieres.size()):
		return
	print("OK: 8 matieres chargees depuis matieres.json")

	var ids_attendus := [
		"pair_impair", "approximation", "terme_manquant", "plan_cartesien",
		"possible_impossible", "tableau_pictogramme", "fractions", "croissant_decroissant"
	]
	for id in ids_attendus:
		if not _verifier(not DataManager.get_matiere_by_id(id).is_empty(), "matiere manquante: " + id):
			return
	print("OK: les 8 ids de matiere attendus sont presents")

	# 2. Instancie une CarteMatiere par matiere (verifie configurer() sans
	#    crash). Icone reelle (ExamenAssetUtil, Phase 8) OU placeholder
	#    colore selon que Mike a deja depose exam_<id>_icon.png ou non —
	#    ne presume pas lequel (Mike a deja depose les 8 icones reelles
	#    en local a ce stade), verifie juste que c'est TOUJOURS l'un des
	#    deux, jamais aucun ni les deux a la fois.
	var CarteMatiereScene := preload("res://scenes/components/CarteMatiere.tscn")
	for matiere in DataManager.matieres:
		var carte = CarteMatiereScene.instantiate()
		root.add_child(carte)
		carte.configurer(matiere)
		var texte_obtenu: String = carte.get_node("%LabelNom").text
		var texte_attendu: String = String(matiere.get("nom"))
		if not _verifier(texte_obtenu == texte_attendu, "nom mal applique pour %s : attendu '%s', obtenu '%s'" % [matiere.get("id"), texte_attendu, texte_obtenu]):
			return
		var placeholder_visible: bool = carte.get_node("%PlaceholderIcone").visible
		var texture_visible: bool = carte.get_node("%TextureIcone").visible
		if not _verifier(placeholder_visible != texture_visible, "exactement un des deux (placeholder OU icone reelle) devrait etre visible pour " + str(matiere.get("id"))):
			return
		if not _verifier(not carte.get_node("%LabelNom").visible, "LabelNom devrait rester cache sous le badge (demande de Mike)"):
			return
		root.remove_child(carte)
		carte.free()
	print("OK: %d cartes de matiere configurees sans erreur (placeholders d'icone actifs)" % DataManager.matieres.size())

	# 3. Verifie l'affichage XP (format utilise par hub.gd).
	SaveManager.delete_save()
	SaveManager.new_game("creature_01")
	SaveManager.add_xp(30)
	if not _verifier(SaveManager.get_xp_total() == 30, "xp total incorrect apres add_xp: obtenu %d" % SaveManager.get_xp_total()):
		return
	print("OK: XP total apres add_xp(30) = %d" % SaveManager.get_xp_total())

	SaveManager.delete_save()
	DataManager.free()
	SaveManager.free()
	print("=== Smoke test Phase 3 : SUCCES ===")
	quit(0)
