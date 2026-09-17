extends SceneTree
## Test de fumee headless pour la Phase 5 (Selection de niveau). Pas
## execute en jeu normal. Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_phase5.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test Phase 5 (selection de niveau) ===")

	var DataManager = preload("res://scripts/autoload/data_manager.gd").new()
	DataManager.reload_all()
	var SaveManager = preload("res://scripts/autoload/save_manager.gd").new()

	# 1. Les 80 fichiers de niveaux existent et ont un nom.
	var ids_matieres := [
		"pair_impair", "approximation", "terme_manquant", "plan_cartesien",
		"possible_impossible", "tableau_pictogramme", "fractions", "croissant_decroissant"
	]
	var total := 0
	for matiere_id in ids_matieres:
		for n in range(1, 11):
			var niveau_id := "niveau_%02d" % n
			var data := DataManager.load_niveau("%s_%s" % [matiere_id, niveau_id])
			if not _verifier(not String(data.get("nom", "")).is_empty(), "nom manquant pour %s_%s" % [matiere_id, niveau_id]):
				return
			total += 1
	if not _verifier(total == 80, "80 fichiers de niveaux attendus, obtenu %d" % total):
		return
	print("OK: les 80 fichiers de niveaux existent avec un nom")

	# 2. L'exemple complet (pair_impair niveau 1) a bien ses 10 questions.
	var exemple := DataManager.load_niveau("pair_impair_niveau_01")
	var questions: Array = exemple.get("questions", [])
	if not _verifier(questions.size() == 10, "l'exemple pair_impair_niveau_01 devrait avoir 10 questions, obtenu %d" % questions.size()):
		return
	print("OK: l'exemple complet pair_impair_niveau_01 a ses 10 questions")

	# 3. Progression : niveau 1 toujours "debloque" (implicite, jamais lu
	# depuis la sauvegarde), niveaux suivants verrouilles par defaut.
	var matiere_test := "pair_impair"
	SaveManager.delete_save()
	SaveManager.new_game("creature_01")
	if not _verifier(not SaveManager.est_niveau_debloque(matiere_test, "niveau_02"), "niveau_02 ne devrait pas etre debloque par defaut"):
		return
	print("OK: niveaux 2+ verrouilles par defaut (niveau 1 gere separement, toujours implicite)")

	# 4. Reussir le niveau 1 (>=7/10) debloque le niveau 2, mais pas le niveau 3.
	SaveManager.set_progression_niveau(matiere_test, "niveau_01", true, 8, true)
	SaveManager.set_progression_niveau(matiere_test, "niveau_02", false, 0, true)  # simule le deblocage fait par ecran_tableau_placeholder.gd
	if not _verifier(SaveManager.est_niveau_debloque(matiere_test, "niveau_02"), "niveau_02 devrait etre debloque apres reussite du niveau_01"):
		return
	if not _verifier(not SaveManager.est_niveau_debloque(matiere_test, "niveau_03"), "niveau_03 ne devrait toujours pas etre debloque"):
		return
	var progression := SaveManager.get_progression_matiere(matiere_test)
	var infos_niveau_01: Dictionary = progression.get("niveaux", {}).get("niveau_01", {})
	if not _verifier(bool(infos_niveau_01.get("reussi", false)) and int(infos_niveau_01.get("meilleur_score", 0)) == 8, "niveau_01 devrait etre marque reussi avec un score de 8"):
		return
	print("OK: reussir un niveau debloque le suivant (et seulement le suivant)")

	# 5. Un echec (< 7/10) ne debloque rien de plus et ne casse pas l'etat existant.
	SaveManager.set_progression_niveau(matiere_test, "niveau_02", false, 3, false)
	if not _verifier(not SaveManager.est_niveau_debloque(matiere_test, "niveau_03"), "un echec au niveau_02 ne devrait pas debloquer niveau_03"):
		return
	if not _verifier(SaveManager.est_niveau_debloque(matiere_test, "niveau_02"), "niveau_02 devrait rester debloque malgre l'echec (deja debloque avant)"):
		return
	print("OK: un echec ne debloque rien de plus et ne verrouille pas retroactivement")

	# 6. Persistance apres reload.
	SaveManager.data = {}
	if not _verifier(SaveManager.load_game(), "echec du rechargement de la sauvegarde"):
		return
	if not _verifier(SaveManager.est_niveau_debloque(matiere_test, "niveau_02"), "le deblocage du niveau_02 devrait persister"):
		return
	print("OK: la progression persiste apres sauvegarde/rechargement")

	SaveManager.delete_save()

	# 7. CarteNiveau : les 3 etats se configurent sans erreur.
	var CarteNiveauScene := preload("res://scenes/components/CarteNiveau.tscn")
	for etat in ["verrouille", "disponible", "reussi"]:
		var carte = CarteNiveauScene.instantiate()
		root.add_child(carte)
		carte.configurer(3, "Niveau de test", etat, 8)
		var texte_attendu_present: bool = carte.text.find("Niveau de test") != -1
		if not _verifier(texte_attendu_present, "le texte de CarteNiveau devrait contenir le nom du niveau (etat: %s)" % etat):
			return
		if not _verifier(carte.disabled == (etat == "verrouille"), "disabled incorrect pour l'etat '%s'" % etat):
			return
		root.remove_child(carte)
		carte.free()
	print("OK: CarteNiveau se configure correctement pour les 3 etats")

	# 8. Structure de SelectionNiveau.tscn (le script racine ne compile pas
	# sous --script, meme limite documentee depuis la Phase 2 - la
	# structure des noeuds reste verifiable). EcranTableau.tscn (Phase 6)
	# a son propre smoke test dedie (smoke_test_phase6.gd).
	var SelectionNiveauScene := preload("res://scenes/SelectionNiveau.tscn")
	var ecran_selection = SelectionNiveauScene.instantiate()
	root.add_child(ecran_selection)
	for chemin in ["%LabelXp", "%BoutonRetour", "%LabelTitre", "%GrilleNiveaux", "%VoileEntree"]:
		if not _verifier(ecran_selection.get_node_or_null(chemin) != null, "noeud manquant dans SelectionNiveau.tscn: " + chemin):
			return
	root.remove_child(ecran_selection)
	ecran_selection.free()
	print("OK: structure de SelectionNiveau.tscn complete")

	DataManager.free()
	SaveManager.free()
	print("=== Smoke test Phase 5 : SUCCES ===")
	quit(0)
