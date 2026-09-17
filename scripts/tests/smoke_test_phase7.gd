extends SceneTree
## Test de fumee headless pour la Phase 7 (rencontre/capture). Pas
## execute en jeu normal. Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_phase7.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test Phase 7 (rencontre/capture) ===")

	# 1. RencontreUtil : fonction pure, testable sans autoload.
	if not _verifier(RencontreUtil.tirer_creature_sauvage([], ["creature_01"]) == "", "toutes_ids vide devrait retourner ''"):
		return
	var tirage_unique := RencontreUtil.tirer_creature_sauvage(["creature_01", "creature_02", "creature_03"], ["creature_01", "creature_02"])
	if not _verifier(tirage_unique == "creature_03", "un seul candidat restant ('creature_03') devrait etre tire, obtenu '%s'" % tirage_unique):
		return
	var tirage_reset := RencontreUtil.tirer_creature_sauvage(["creature_01", "creature_02", "creature_03"], ["creature_01", "creature_02", "creature_03"])
	if not _verifier(["creature_01", "creature_02", "creature_03"].has(tirage_reset), "toutes vues -> devrait retirer parmi l'ensemble complet, obtenu '%s'" % tirage_reset):
		return
	print("OK: RencontreUtil.tirer_creature_sauvage() (aucun candidat, un seul, reset si toutes vues)")

	# 2. SaveManager : marquer_vue() persiste desormais (bug trouve en Phase 6/7).
	var SaveManager = preload("res://scripts/autoload/save_manager.gd").new()
	SaveManager.delete_save()
	SaveManager.new_game("creature_01")
	SaveManager.marquer_vue("creature_02")
	SaveManager.data = {}
	if not _verifier(SaveManager.load_game(), "echec du rechargement apres marquer_vue()"):
		return
	if not _verifier(SaveManager.get_creatures_vues().has("creature_02"), "marquer_vue() devrait persister sur disque"):
		return
	print("OK: marquer_vue() sauvegarde bien sur disque")

	# 3. Rencontres : une creature assignee a un tableau y reste associee
	# (rejoue toujours la meme, meme apres un echec/nouvel essai).
	var tableau_id := "pair_impair_niveau_01"
	if not _verifier(SaveManager.get_creature_rencontre(tableau_id) == "", "aucune rencontre ne devrait exister avant le premier tirage"):
		return
	SaveManager.definir_creature_rencontre(tableau_id, "creature_03")
	if not _verifier(SaveManager.get_creature_rencontre(tableau_id) == "creature_03", "la rencontre devrait etre memorisee"):
		return
	SaveManager.data = {}
	if not _verifier(SaveManager.load_game(), "echec du rechargement apres definir_creature_rencontre()"):
		return
	if not _verifier(SaveManager.get_creature_rencontre(tableau_id) == "creature_03", "la rencontre devrait persister apres reload"):
		return
	print("OK: la creature assignee a un tableau persiste (meme creature a chaque revisite)")

	# 4. Capture reelle : succes -> creature_capturee vrai la 1ere fois,
	# faux la 2e fois (deja dans le roster).
	var deja_capturee_avant: bool = SaveManager.get_creatures_capturees().has("creature_03")
	if not _verifier(not deja_capturee_avant, "creature_03 ne devrait pas encore etre capturee"):
		return
	SaveManager.capturer_creature("creature_03")
	if not _verifier(SaveManager.get_creatures_capturees().has("creature_03"), "creature_03 devrait etre capturee"):
		return
	SaveManager.data = {}
	if not _verifier(SaveManager.load_game(), "echec du rechargement apres capturer_creature()"):
		return
	if not _verifier(SaveManager.get_creatures_capturees().has("creature_03"), "la capture devrait persister apres reload"):
		return
	print("OK: la capture persiste, et le statut 'deja capturee' est detectable avant l'appel")

	SaveManager.delete_save()

	# 5. Structure de EcranTableau.tscn : les noeuds cote "creature sauvage"
	# sont bien presents (script racine non compile sous --script, meme
	# limite documentee depuis la Phase 2).
	var EcranTableauScene := preload("res://scenes/EcranTableau.tscn")
	var ecran = EcranTableauScene.instantiate()
	root.add_child(ecran)
	for chemin in ["%TextureSauvage", "%PlaceholderSauvage", "%LabelSauvage", "%LabelNomSauvage"]:
		if not _verifier(ecran.get_node_or_null(chemin) != null, "noeud manquant dans EcranTableau.tscn: " + chemin):
			return
	root.remove_child(ecran)
	ecran.free()
	print("OK: structure de EcranTableau.tscn completee pour la rencontre")

	SaveManager.free()
	print("=== Smoke test Phase 7 : SUCCES ===")
	quit(0)
