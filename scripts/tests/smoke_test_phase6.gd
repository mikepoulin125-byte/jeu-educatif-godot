extends SceneTree
## Test de fumee headless pour la Phase 6 (scenes de tableau). Pas
## execute en jeu normal. Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_phase6.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).
## Les 8 widgets de scripts/tableau/ ne referencent aucun autoload, donc
## (contrairement a ecran_tableau.gd) ils compilent et s'executent
## normalement sous --script : testes ici en profondeur (configurer() +
## simulation de reponse correcte/incorrecte). ecran_tableau.gd lui-meme
## n'est verifie que structurellement (meme limite documentee depuis la
## Phase 2/3) - son orchestration complete (XP/berries/resultats/
## deblocage) est verifiee par une partie reelle jouee en conditions
## reelles (voir docs/phases/phase_06_scenes_tableau.md).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test Phase 6 (scenes de tableau) ===")

	# 1. Validation du contenu des 80 fichiers de niveaux (schema par matiere).
	var DataManager = preload("res://scripts/autoload/data_manager.gd").new()
	DataManager.reload_all()

	var schemas_attendus := {
		"pair_impair": ["nombre", "reponse"],
		"approximation": ["texte", "min", "max"],
		"terme_manquant": ["texte", "reponse"],
		"possible_impossible": ["texte", "reponse"],
		"tableau_pictogramme": ["texte", "reponse"],
		"fractions": ["texte", "choix", "reponse_index"],
		"croissant_decroissant": ["suite", "reponse"],
	}
	for matiere_id in schemas_attendus.keys():
		for n in range(1, 11):
			var niveau_id := "niveau_%02d" % n
			var data := DataManager.load_niveau("%s_%s" % [matiere_id, niveau_id])
			var questions: Array = data.get("questions", [])
			if not _verifier(questions.size() == 10, "%s_%s : 10 questions attendues, obtenu %d" % [matiere_id, niveau_id, questions.size()]):
				return
			for champ in schemas_attendus[matiere_id]:
				if not _verifier(questions[0].has(champ), "%s_%s : champ '%s' manquant dans la 1ere question" % [matiere_id, niveau_id, champ]):
					return
			if matiere_id == "tableau_pictogramme" and not _verifier(data.has("graphique") and data["graphique"].get("barres", []).size() > 0, "%s_%s : graphique manquant ou vide" % [matiere_id, niveau_id]):
				return
	print("OK: les 79 fichiers de niveaux (hors plan_cartesien, verifie separement) ont le schema attendu pour leur matiere")

	# 1bis. plan_cartesien : en cours de refonte tableau par tableau (voir
	# CLAUDE.md badge 4), donc chaque niveau peut avoir un schema
	# different tant que la refonte n'est pas terminee. Niveaux refaits
	# (NIVEAUX_PC_CHAMPS) : schema selon leur type de question. Les
	# autres : ancien schema (x/y/taille_grille, plus utilise par le
	# widget actuel, en attente de refonte).
	var niveaux_pc_champs := {
		1: ["taille_grille", "increment", "axe_manquant", "position", "reponse"],
		2: ["taille_grille", "increment", "axe_manquant", "position", "reponse"],
		3: ["type", "id_creature", "x", "y", "taille_grille"],
		4: ["type", "id_creature", "x", "y", "taille_grille"],
	}
	for n in range(1, 11):
		var niveau_id := "niveau_%02d" % n
		var data := DataManager.load_niveau("plan_cartesien_%s" % niveau_id)
		var questions: Array = data.get("questions", [])
		if not _verifier(questions.size() == 10, "plan_cartesien_%s : 10 questions attendues, obtenu %d" % [niveau_id, questions.size()]):
			return
		var champs: Array = niveaux_pc_champs.get(n, ["x", "y", "taille_grille"])
		for champ in champs:
			if not _verifier(questions[0].has(champ), "plan_cartesien_%s : champ '%s' manquant dans la 1ere question" % [niveau_id, champ]):
				return
	print("OK: les 10 fichiers de niveaux plan_cartesien ont le schema attendu (%d refaits, %d en attente)" % [niveaux_pc_champs.size(), 10 - niveaux_pc_champs.size()])

	# 2. Widget pair_impair.
	var scene_pi := preload("res://scenes/tableau/WidgetPairImpair.tscn")
	var w_pi = scene_pi.instantiate()
	root.add_child(w_pi)
	var resultat_pi = {"valeur": null}
	w_pi.reponse_donnee.connect(func(c): resultat_pi["valeur"] = c)
	w_pi.configurer({"nombre": 4, "reponse": "pair"}, {})
	w_pi._repondre("pair")
	if not _verifier(resultat_pi["valeur"] == true, "pair_impair : 'pair' sur 4 devrait etre correct"):
		return
	w_pi.configurer({"nombre": 7, "reponse": "impair"}, {})
	w_pi._repondre("pair")
	if not _verifier(resultat_pi["valeur"] == false, "pair_impair : 'pair' sur 7 (impair) devrait etre incorrect"):
		return
	root.remove_child(w_pi)
	w_pi.free()
	print("OK: widget pair_impair (bonne et mauvaise reponse)")

	# 3. Widget approximation (plage min/max).
	var scene_approx := preload("res://scenes/tableau/WidgetApproximation.tscn")
	var w_approx = scene_approx.instantiate()
	root.add_child(w_approx)
	var resultat_approx = {"valeur": null}
	w_approx.reponse_donnee.connect(func(c): resultat_approx["valeur"] = c)
	w_approx.configurer({"texte": "Estime.", "min": 10, "max": 20}, {})
	w_approx.get_node("%ChampReponse").text = "15"
	w_approx._valider()
	if not _verifier(resultat_approx["valeur"] == true, "approximation : 15 dans [10,20] devrait etre correct"):
		return
	w_approx.configurer({"texte": "Estime.", "min": 10, "max": 20}, {})
	w_approx.get_node("%ChampReponse").text = "50"
	w_approx._valider()
	if not _verifier(resultat_approx["valeur"] == false, "approximation : 50 hors [10,20] devrait etre incorrect"):
		return
	root.remove_child(w_approx)
	w_approx.free()
	print("OK: widget approximation (plage min/max)")

	# 4. Widget terme_manquant (reponse exacte).
	var scene_tm := preload("res://scenes/tableau/WidgetTermeManquant.tscn")
	var w_tm = scene_tm.instantiate()
	root.add_child(w_tm)
	var resultat_tm = {"valeur": null}
	w_tm.reponse_donnee.connect(func(c): resultat_tm["valeur"] = c)
	w_tm.configurer({"texte": "7 - ? = 2", "reponse": 5}, {})
	w_tm.get_node("%ChampReponse").text = "5"
	w_tm._valider()
	if not _verifier(resultat_tm["valeur"] == true, "terme_manquant : reponse exacte devrait etre correcte"):
		return
	root.remove_child(w_tm)
	w_tm.free()
	print("OK: widget terme_manquant")

	# 5. Widget plan_cartesien (tableau 1 : graduation manquante a ecrire).
	var scene_pc := preload("res://scenes/tableau/WidgetPlanCartesien.tscn")
	var w_pc = scene_pc.instantiate()
	root.add_child(w_pc)
	var resultat_pc = {"valeur": null}
	w_pc.reponse_donnee.connect(func(c): resultat_pc["valeur"] = c)
	w_pc.configurer({"taille_grille": 5, "increment": 1, "axe_manquant": "x", "position": 2, "reponse": 3}, {})
	var vue: PlanCartesienView = w_pc.get_node("%Vue")
	var zone_depot_pc: ZoneDepotPlanCartesien = w_pc.get_node("%ZonePlacement")
	if not _verifier(not zone_depot_pc.actif, "plan_cartesien : la zone de depot ne devrait pas accepter de glisser-depose hors du tableau 'placer_point'"):
		return
	if not _verifier(vue.indice_x_marque == 2, "plan_cartesien : la graduation X 2 (0-based) devrait etre marquee"):
		return
	if not _verifier(vue.etiquettes_y[0] == "1" and vue.etiquettes_y[4] == "5", "plan_cartesien : l'axe Y devrait etre complet (1 a 5)"):
		return
	if not _verifier(vue.etiquettes_x[2] == null, "plan_cartesien : la graduation X marquee ne doit pas afficher de texte"):
		return
	w_pc.get_node("%ChampReponse").text = "3"
	w_pc._valider()
	if not _verifier(resultat_pc["valeur"] == true, "plan_cartesien : reponse exacte (3) devrait etre correcte"):
		return
	w_pc.configurer({"taille_grille": 5, "increment": 1, "axe_manquant": "y", "position": 0, "reponse": 1}, {})
	if not _verifier(vue.indice_y_marque == 0, "plan_cartesien : axe_manquant='y' devrait marquer l'axe Y"):
		return
	w_pc.get_node("%ChampReponse").text = "4"
	w_pc._valider()
	if not _verifier(resultat_pc["valeur"] == false, "plan_cartesien : reponse fausse (4 au lieu de 1) devrait etre incorrecte"):
		return
	# 5bis. Widget plan_cartesien (tableau 3 : lire les coordonnees d'une creature placee).
	w_pc.configurer({"type": "lire_coordonnees", "taille_grille": 5, "id_creature": 4, "x": 2, "y": 4}, {})
	if not _verifier(vue.etiquettes_x[0] == "1" and vue.etiquettes_x[4] == "5", "plan_cartesien : lire_coordonnees devrait afficher l'axe X complet"):
		return
	if not _verifier(vue.etiquettes_y[0] == "1" and vue.etiquettes_y[4] == "5", "plan_cartesien : lire_coordonnees devrait afficher l'axe Y complet"):
		return
	var zone_creature: Control = w_pc.get_node("%ZoneCreature")
	if not _verifier(zone_creature.visible, "plan_cartesien : lire_coordonnees devrait afficher la creature"):
		return
	w_pc.get_node("%ChampX").text = "2"
	w_pc.get_node("%ChampY").text = "4"
	w_pc._valider_coordonnees()
	if not _verifier(resultat_pc["valeur"] == true, "plan_cartesien : coordonnees exactes (2,4) devraient etre correctes"):
		return
	w_pc.configurer({"type": "lire_coordonnees", "taille_grille": 5, "id_creature": 4, "x": 2, "y": 4}, {})
	w_pc.get_node("%ChampX").text = "2"
	w_pc.get_node("%ChampY").text = "1"
	w_pc._valider_coordonnees()
	if not _verifier(resultat_pc["valeur"] == false, "plan_cartesien : coordonnee Y fausse (1 au lieu de 4) devrait etre incorrecte"):
		return
	# 5ter. Widget plan_cartesien (tableau 4 : deplacer la creature - clic sur intersection, glisser-depose, confirmer).
	w_pc.configurer({"type": "placer_point", "taille_grille": 6, "id_creature": 8, "x": 4, "y": 6}, {})
	var zone_depart: Control = w_pc.get_node("%ZoneDepart")
	var bouton_confirmer: Button = w_pc.get_node("%BoutonConfirmer")
	if not _verifier(zone_depot_pc.actif, "plan_cartesien : la zone de depot devrait accepter le glisser-depose pendant 'placer_point'"):
		return
	if not _verifier(zone_depart.visible, "plan_cartesien : placer_point devrait afficher la zone de depart"):
		return
	if not _verifier(bouton_confirmer.disabled, "plan_cartesien : Confirmer devrait etre desactive avant tout placement"):
		return
	var nb_intersections: int = w_pc._boutons_intersections.size()
	if not _verifier(nb_intersections == 49, "plan_cartesien : grille 6x6 devrait avoir 49 intersections (7x7), obtenu %d" % nb_intersections):
		return
	w_pc._on_intersection_pressee(1, 2)
	if not _verifier(not bouton_confirmer.disabled, "plan_cartesien : Confirmer devrait s'activer apres un premier placement"):
		return
	w_pc._valider_placement()
	if not _verifier(resultat_pc["valeur"] == false, "plan_cartesien : placement (1,2) sur cible (4,6) devrait etre incorrect"):
		return
	# Glisser-depose simule : _on_creature_deposee() ne dependant que de
	# la position de la souris (via get_local_mouse_position(), non
	# pilotable en headless), on verifie plutot _placer_creature_a()
	# directement - c'est la fonction qu'il appelle une fois la
	# coordonnee la plus proche calculee.
	w_pc.configurer({"type": "placer_point", "taille_grille": 6, "id_creature": 8, "x": 4, "y": 6}, {})
	w_pc._placer_creature_a(4, 6)
	w_pc._valider_placement()
	if not _verifier(resultat_pc["valeur"] == true, "plan_cartesien : placement exact (4,6) devrait etre correct"):
		return
	root.remove_child(w_pc)
	w_pc.free()
	print("OK: widget plan_cartesien (graduation manquante + coordonnees lues + creature placee/confirmee, bonnes et mauvaises reponses)")

	# 6. Widget possible_impossible.
	var scene_poss := preload("res://scenes/tableau/WidgetPossibleImpossible.tscn")
	var w_poss = scene_poss.instantiate()
	root.add_child(w_poss)
	var resultat_poss = {"valeur": null}
	w_poss.reponse_donnee.connect(func(c): resultat_poss["valeur"] = c)
	w_poss.configurer({"texte": "...", "reponse": "possible"}, {})
	w_poss._repondre("possible")
	if not _verifier(resultat_poss["valeur"] == true, "possible_impossible : reponse correcte attendue"):
		return
	root.remove_child(w_poss)
	w_poss.free()
	print("OK: widget possible_impossible")

	# 7. Widget tableau_pictogramme (graphique partage + question numerique).
	var scene_tp := preload("res://scenes/tableau/WidgetTableauPictogramme.tscn")
	var w_tp = scene_tp.instantiate()
	root.add_child(w_tp)
	var resultat_tp = {"valeur": null}
	w_tp.reponse_donnee.connect(func(c): resultat_tp["valeur"] = c)
	var graphique_test := {"titre": "Test", "barres": [{"categorie": "A", "valeur": 3}, {"categorie": "B", "valeur": 7}]}
	w_tp.configurer({"texte": "Combien de A ?", "reponse": 3}, {"graphique": graphique_test})
	var nb_barres: int = w_tp.get_node("%ZoneBarres").get_child_count()
	if not _verifier(nb_barres == 2, "tableau_pictogramme : 2 barres attendues, obtenu %d" % nb_barres):
		return
	w_tp.get_node("%ChampReponse").text = "3"
	w_tp._valider()
	if not _verifier(resultat_tp["valeur"] == true, "tableau_pictogramme : reponse exacte devrait etre correcte"):
		return
	root.remove_child(w_tp)
	w_tp.free()
	print("OK: widget tableau_pictogramme (graphique construit + reponse correcte)")

	# 8. Widget fractions.
	var scene_fr := preload("res://scenes/tableau/WidgetFractions.tscn")
	var w_fr = scene_fr.instantiate()
	root.add_child(w_fr)
	var resultat_fr = {"valeur": null}
	w_fr.reponse_donnee.connect(func(c): resultat_fr["valeur"] = c)
	w_fr.configurer({"texte": "...", "choix": ["1/2", "1/3", "1/4"], "reponse_index": 1}, {})
	w_fr._repondre(1)
	if not _verifier(resultat_fr["valeur"] == true, "fractions : index correct attendu"):
		return
	w_fr.configurer({"texte": "...", "choix": ["1/2", "1/3", "1/4"], "reponse_index": 1}, {})
	w_fr._repondre(0)
	if not _verifier(resultat_fr["valeur"] == false, "fractions : mauvais index devrait etre incorrect"):
		return
	root.remove_child(w_fr)
	w_fr.free()
	print("OK: widget fractions")

	# 9. Widget croissant_decroissant.
	var scene_cd := preload("res://scenes/tableau/WidgetCroissantDecroissant.tscn")
	var w_cd = scene_cd.instantiate()
	root.add_child(w_cd)
	var resultat_cd = {"valeur": null}
	w_cd.reponse_donnee.connect(func(c): resultat_cd["valeur"] = c)
	w_cd.configurer({"suite": [2, 5, 8, 11], "reponse": "croissant"}, {})
	if not _verifier(w_cd.get_node("%LabelSuite").text == "2, 5, 8, 11", "croissant_decroissant : affichage de la suite incorrect"):
		return
	w_cd._repondre("croissant")
	if not _verifier(resultat_cd["valeur"] == true, "croissant_decroissant : reponse correcte attendue"):
		return
	root.remove_child(w_cd)
	w_cd.free()
	print("OK: widget croissant_decroissant")

	# 10. Structure de EcranTableau.tscn (le script racine ne compile pas
	# sous --script car il reference des autoloads, meme limite
	# documentee depuis la Phase 2).
	var EcranTableauScene := preload("res://scenes/EcranTableau.tscn")
	var ecran = EcranTableauScene.instantiate()
	root.add_child(ecran)
	var noeuds_attendus := [
		"%LabelXp", "%BoutonQuitter", "%LabelTitre", "%LabelQuestion", "%LabelFeedback",
		"%ZoneReponse", "%TextureJoueur", "%PlaceholderJoueur", "%PlaceholderSauvage",
		"%TimerAvance", "%PanneauResultats", "%LabelResultatsTitre", "%LabelResultatsDetails", "%BoutonContinuer"
	]
	for chemin in noeuds_attendus:
		if not _verifier(ecran.get_node_or_null(chemin) != null, "noeud manquant dans EcranTableau.tscn: " + chemin):
			return
	root.remove_child(ecran)
	ecran.free()
	print("OK: structure de EcranTableau.tscn complete")

	DataManager.free()
	print("=== Smoke test Phase 6 : SUCCES ===")
	quit(0)
