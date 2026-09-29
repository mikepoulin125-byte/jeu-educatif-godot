extends SceneTree
## Test de fumee headless pour le "11e niveau" (examen) et la refonte
## visuelle de SelectionNiveau (grille 5x2 + chemin procedural). Pas
## execute en jeu normal. Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_examen.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test examen (11e niveau) + chemin de niveaux ===")

	# 1. SaveManager.ajouter_question_ratee()/get_questions_ratees() :
	# ajout, deduplication, persistance, isolation par matiere.
	var SaveManager = preload("res://scripts/autoload/save_manager.gd").new()
	SaveManager.delete_save()
	SaveManager.new_game("creature_01")

	var q1 := {"texte": "2 + 2 = ?", "reponse": 4}
	var q2 := {"texte": "3 + 3 = ?", "reponse": 6}
	var ctx := {"graphique": {}}

	if not _verifier(SaveManager.get_questions_ratees("terme_manquant").is_empty(), "aucune question ratee au depart"):
		return
	SaveManager.ajouter_question_ratee("terme_manquant", q1, ctx)
	SaveManager.ajouter_question_ratee("terme_manquant", q1, ctx)  # doublon, ne doit pas dupliquer
	SaveManager.ajouter_question_ratee("terme_manquant", q2, ctx)
	SaveManager.ajouter_question_ratee("fractions", q1, ctx)  # autre matiere, liste separee

	var ratees_terme := SaveManager.get_questions_ratees("terme_manquant")
	if not _verifier(ratees_terme.size() == 2, "2 questions ratees uniques attendues pour terme_manquant, obtenu %d" % ratees_terme.size()):
		return
	if not _verifier(SaveManager.get_questions_ratees("fractions").size() == 1, "1 question ratee attendue pour fractions (isolation par matiere)"):
		return

	SaveManager.data = {}
	if not _verifier(SaveManager.load_game(), "echec du rechargement apres ajouter_question_ratee()"):
		return
	if not _verifier(SaveManager.get_questions_ratees("terme_manquant").size() == 2, "les questions ratees devraient persister apres reload"):
		return
	print("OK: ajouter_question_ratee()/get_questions_ratees() - ajout, dedup, isolation par matiere, persistance")

	# 2. set_progression_niveau() avec "total" variable : meilleur_total
	# suit toujours le meilleur_score (pas un total record independant).
	SaveManager.set_progression_niveau("terme_manquant", "examen", false, 4, true, 6)
	var infos: Dictionary = SaveManager.get_progression_matiere("terme_manquant").get("niveaux", {}).get("examen", {})
	if not _verifier(int(infos.get("meilleur_score", -1)) == 4 and int(infos.get("meilleur_total", -1)) == 6, "meilleur_score/meilleur_total incorrects apres 1er essai (4/6)"):
		return
	SaveManager.set_progression_niveau("terme_manquant", "examen", true, 8, true, 10)
	infos = SaveManager.get_progression_matiere("terme_manquant").get("niveaux", {}).get("examen", {})
	if not _verifier(int(infos.get("meilleur_score", -1)) == 8 and int(infos.get("meilleur_total", -1)) == 10, "meilleur_score/meilleur_total devraient suivre le nouveau record (8/10)"):
		return
	SaveManager.set_progression_niveau("terme_manquant", "examen", false, 3, true, 5)
	infos = SaveManager.get_progression_matiere("terme_manquant").get("niveaux", {}).get("examen", {})
	if not _verifier(int(infos.get("meilleur_score", -1)) == 8 and int(infos.get("meilleur_total", -1)) == 10, "un essai plus faible (3/5) ne devrait pas ecraser le record (8/10)"):
		return
	print("OK: set_progression_niveau() associe correctement meilleur_total au meilleur_score")

	SaveManager.delete_save()
	SaveManager.free()

	# 3. ExamenUtil.construire_questions() : priorise les ratees, complete
	# avec le pool "deja vues" si besoin, jamais plus de 10, jamais de
	# doublon, et fonctionne avec MOINS de 10 si le contenu est insuffisant.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var ratees := []
	for i in range(3):
		ratees.append({"question": {"texte": "ratee_%d" % i}, "contexte": {}})
	var pool_vues := []
	for i in range(20):
		pool_vues.append({"question": {"texte": "vue_%d" % i}, "contexte": {}})

	var resultat := ExamenUtil.construire_questions(ratees, pool_vues, rng)
	if not _verifier(resultat.size() == ExamenUtil.NB_QUESTIONS_EXAMEN, "l'examen devrait avoir %d questions quand le pool est suffisant, obtenu %d" % [ExamenUtil.NB_QUESTIONS_EXAMEN, resultat.size()]):
		return
	var nb_ratees_incluses := 0
	for entree in resultat:
		if String(entree["question"]["texte"]).begins_with("ratee_"):
			nb_ratees_incluses += 1
	if not _verifier(nb_ratees_incluses == 3, "les 3 questions ratees devraient TOUTES etre incluses (priorite), obtenu %d" % nb_ratees_incluses):
		return
	# Pas de doublon.
	var vus := {}
	var doublon := false
	for entree in resultat:
		var cle: String = JSON.stringify(entree)
		if vus.has(cle):
			doublon = true
		vus[cle] = true
	if not _verifier(not doublon, "aucune question ne devrait apparaitre deux fois dans l'examen"):
		return
	print("OK: construire_questions() priorise les ratees et complete avec le pool 'deja vues' sans doublon")

	var resultat_insuffisant := ExamenUtil.construire_questions(ratees, [], rng)
	if not _verifier(resultat_insuffisant.size() == 3, "avec seulement 3 questions disponibles et aucun pool de secours, l'examen devrait avoir 3 questions (pas bloque), obtenu %d" % resultat_insuffisant.size()):
		return
	print("OK: construire_questions() reste jouable (moins de 10 questions) quand le contenu disponible est insuffisant")

	# 4. CarteNiveau : variante "Examen" (texte + icone coin).
	var CarteNiveauScene := preload("res://scenes/components/CarteNiveau.tscn")
	var carte = CarteNiveauScene.instantiate()
	root.add_child(carte)
	carte.configurer_examen("verrouille", 0, 10)
	if not _verifier(carte.disabled, "l'examen verrouille devrait etre desactive"):
		return
	carte.configurer_examen("disponible", 0, 10)
	if not _verifier(not carte.disabled, "l'examen disponible ne devrait pas etre desactive"):
		return
	carte.configurer_examen("reussi", 9, 10)
	if not _verifier(carte.text.find("9/10") != -1, "le texte de l'examen reussi devrait afficher le score/total"):
		return
	# Demande explicite de Mike : contour VERT (pas rouge) quand l'examen
	# est reussi. Verifie directement la couleur du style applique (pas
	# juste le texte) pour en avoir la preuve.
	var style_applique: StyleBoxFlat = carte.get_theme_stylebox("normal")
	var couleur_verte := Color(0.15, 0.6, 0.3, 1)
	if not _verifier(style_applique.border_color.is_equal_approx(couleur_verte), "le contour de l'examen reussi devrait etre vert (%s), obtenu %s" % [couleur_verte, style_applique.border_color]):
		return
	print("OK: le contour de la carte Examen devient vert quand elle est reussie")
	carte.afficher_icone_coin(null)
	var icone: TextureRect = carte.get_node("%IconeCoin")
	if not _verifier(not icone.visible, "IconeCoin devrait rester cachee quand aucune texture n'est fournie"):
		return
	# Reduite de 30% (demande de Mike) par rapport a la taille precedente
	# de 108x108 -> 76x76 (108 * 0.7 = 75.6, arrondi a 76).
	var taille_icone: Vector2 = icone.get_rect().size
	if not _verifier(is_equal_approx(taille_icone.x, 76.0) and is_equal_approx(taille_icone.y, 76.0), "IconeCoin devrait faire 76x76 (reduite de 30%%), obtenu %s" % taille_icone):
		return
	print("OK: IconeCoin fait 76x76 (reduite de 30%% par rapport a la taille precedente)")
	root.remove_child(carte)
	carte.free()
	print("OK: CarteNiveau.configurer_examen()/afficher_icone_coin() fonctionnent correctement")

	# 5. ExamenAssetUtil : une icone PAR MATIERE (confirme par Mike), nom
	# de fichier relie au meme "id" que matieres.json. Null tant qu'aucun
	# fichier n'est depose (utilise un id bidon qui n'aura jamais de
	# fichier reel, plutot qu'une vraie matiere : Mike a deja depose ses
	# 8 icones reelles en local, donc "fractions" etc. ne sont plus null
	# ici — meme situation deja documentee pour logo_menu.png/
	# clic_bouton.mp3/fond_menu.ogv).
	if not _verifier(ExamenAssetUtil.charger_icone("matiere_bidon_inexistante") == null, "charger_icone() devrait etre null pour une matiere sans fichier depose"):
		return
	if not _verifier(ExamenAssetUtil.chemin_icone("fractions") != ExamenAssetUtil.chemin_icone("pair_impair"), "deux matieres differentes devraient resoudre vers deux chemins d'icone differents"):
		return
	if not _verifier(ExamenAssetUtil.chemin_icone("fractions") == "res://assets/ui/examen/exam_fractions_icon.png", "convention de nommage inattendue pour chemin_icone('fractions')"):
		return
	print("OK: ExamenAssetUtil resout une icone distincte par matiere (exam_<id>_icon.png), null tant qu'absente")

	# 6. CheminNiveaux : accepte des points sans planter (rendu procedural,
	# non verifiable visuellement en headless — voir le rapport).
	var CheminNiveauxScript := preload("res://scripts/components/chemin_niveaux.gd")
	var chemin = CheminNiveauxScript.new()
	chemin.definir_points([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)])
	if not _verifier(chemin._points.size() == 3, "definir_points() devrait stocker les points fournis"):
		return
	chemin.free()
	print("OK: CheminNiveaux.definir_points() stocke les points sans erreur")

	# 7. Structure de SelectionNiveau.tscn : nouveaux noeuds presents
	# (script racine ne compile pas sous --script, meme limite
	# documentee depuis la Phase 2 - structure verifiable quand meme).
	var SelectionNiveauScene := preload("res://scenes/SelectionNiveau.tscn")
	var ecran = SelectionNiveauScene.instantiate()
	root.add_child(ecran)
	for chemin_noeud in ["%GrilleNiveaux", "%CheminNiveaux", "%ZoneExamen"]:
		if not _verifier(ecran.get_node_or_null(chemin_noeud) != null, "noeud manquant dans SelectionNiveau.tscn: " + chemin_noeud):
			return
	var grille: GridContainer = ecran.get_node("%GrilleNiveaux")
	if not _verifier(grille.columns == 5, "GrilleNiveaux devrait avoir 5 colonnes (grille 5x2 pour 10 niveaux)"):
		return
	root.remove_child(ecran)
	ecran.free()
	print("OK: SelectionNiveau.tscn a la grille 5 colonnes + les noeuds CheminNiveaux/ZoneExamen")

	print("=== Smoke test examen : SUCCES ===")
	quit(0)
