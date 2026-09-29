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
	print("OK: structure de EcranTableau.tscn completee pour la rencontre")

	# 6. Structure de la barre de berries (Phase 8, demande de Mike :
	# anim de gain XP/berry apres chaque bonne reponse) : noeuds presents,
	# placeholder visible par defaut (aucune icone forcee), compteur a 0.
	for chemin in ["%BarreBerries", "%IconeBerryBarre", "%PlaceholderBerryBarre", "%LabelCompteBerries"]:
		if not _verifier(ecran.get_node_or_null(chemin) != null, "noeud manquant dans EcranTableau.tscn: " + chemin):
			return
	var label_compte: Label = ecran.get_node("%LabelCompteBerries")
	if not _verifier(label_compte.text == "x 0", "LabelCompteBerries devrait afficher 'x 0' par defaut dans le .tscn, obtenu '%s'" % label_compte.text):
		return
	print("OK: structure de la barre de berries (EcranTableau.tscn) complete, compteur a 0 par defaut")

	# 7. Fond remplacable (Phase 8, demande de Mike, un par matiere) :
	# noeuds presents, placeholder (fond uni) visible par defaut.
	for chemin in ["%Fond", "%TextureFond"]:
		if not _verifier(ecran.get_node_or_null(chemin) != null, "noeud manquant dans EcranTableau.tscn: " + chemin):
			return
	var fond: ColorRect = ecran.get_node("%Fond")
	var texture_fond: TextureRect = ecran.get_node("%TextureFond")
	if not _verifier(fond.visible and not texture_fond.visible, "fond uni devrait etre visible par defaut dans le .tscn (texture cachee)"):
		return
	print("OK: fond remplacable par matiere en place (EcranTableau.tscn), fond uni par defaut")

	# 8. Bug corrige (Mike) : le bouton Quitter ne repondait plus aux
	# clics en pleine partie car ZoneReponse (plein ecran, ajoutee APRES
	# BoutonQuitter dans l'arbre donc dessinee/priorisee par-dessus)
	# absorbait tous les clics sur toute sa surface (mouse_filter STOP
	# par defaut sur un Control). mouse_filter=IGNORE laisse les clics
	# passer a travers les zones vides de ZoneReponse.
	var zone_reponse: Control = ecran.get_node("%ZoneReponse")
	if not _verifier(zone_reponse.mouse_filter == Control.MOUSE_FILTER_IGNORE, "ZoneReponse devrait avoir mouse_filter=IGNORE (sinon elle bloque les clics sur BoutonQuitter derriere elle)"):
		return
	print("OK: ZoneReponse ne bloque plus les clics sur BoutonQuitter (mouse_filter=IGNORE)")

	# 9. TableauAssetUtil : UN SEUL fond partage par tous les tableaux
	# (Mike a change d'avis : c'etait un fond par matiere), plusieurs
	# extensions acceptees (jpeg/jpg/png). Mike a reellement depose
	# assets/ui/tableau/fond.jpeg, donc chemin_fond() doit le trouver.
	if not _verifier(TableauAssetUtil.chemin_fond() == "res://assets/ui/tableau/fond.jpeg", "chemin_fond() devrait trouver fond.jpeg (deja depose par Mike), obtenu '%s'" % TableauAssetUtil.chemin_fond()):
		return
	if not _verifier(TableauAssetUtil.charger_fond() is Texture2D, "charger_fond() devrait charger fond.jpeg deja depose"):
		return
	print("OK: TableauAssetUtil resout UN SEUL fond partage (jpeg/jpg/png)")

	# 10. Animation d'impact (Phase 8, demande de Mike) : ZoneJoueur et
	# ZoneSauvage nommes de facon unique (deplaces par tween pendant
	# l'anim de lunge/recul), TextureSauvage a un ShaderMaterial avec le
	# parametre "intensite" (flash blanc a l'impact, voir
	# shaders/flash_blanc.gdshader).
	for chemin in ["%ZoneJoueur", "%ZoneSauvage"]:
		if not _verifier(ecran.get_node_or_null(chemin) != null, "noeud manquant dans EcranTableau.tscn: " + chemin):
			return
	# 10b. Positionnement sur les 2 zones rondes vert fonce du fond
	# (Mike a fourni assets/ui/tableau/fondzones.jpeg avec un point rouge =
	# joueur et un point bleu = creature sauvage pour reperer les centres
	# exacts) : ancrage proportionnel (anchor_left=anchor_right,
	# anchor_top=anchor_bottom) sur ces fractions d'ecran, pas des offsets
	# fixes en pixels (sinon les zones ne suivraient pas le fond qui
	# remplit tout l'ecran a des resolutions differentes).
	var zone_joueur: Control = ecran.get_node("%ZoneJoueur")
	var zone_sauvage: Control = ecran.get_node("%ZoneSauvage")
	if not _verifier(is_equal_approx(zone_joueur.anchor_left, zone_joueur.anchor_right) and is_equal_approx(zone_joueur.anchor_top, zone_joueur.anchor_bottom), "ZoneJoueur devrait etre ancre par point (anchor_left=anchor_right, anchor_top=anchor_bottom) pour suivre le fond proportionnellement"):
		return
	if not _verifier(absf(zone_joueur.anchor_left - 0.270725) < 0.001 and absf(zone_joueur.anchor_top - 0.762232) < 0.001, "ZoneJoueur devrait etre centre sur le point rouge de fondzones.jpeg (~27.1%%, 76.2%%), obtenu (%f, %f)" % [zone_joueur.anchor_left, zone_joueur.anchor_top]):
		return
	if not _verifier(is_equal_approx(zone_sauvage.anchor_left, zone_sauvage.anchor_right) and is_equal_approx(zone_sauvage.anchor_top, zone_sauvage.anchor_bottom), "ZoneSauvage devrait etre ancre par point (anchor_left=anchor_right, anchor_top=anchor_bottom) pour suivre le fond proportionnellement"):
		return
	if not _verifier(absf(zone_sauvage.anchor_left - 0.696495) < 0.001 and absf(zone_sauvage.anchor_top - 0.472642) < 0.001, "ZoneSauvage devrait etre centre sur le point bleu de fondzones.jpeg (~69.6%%, 47.3%%), obtenu (%f, %f)" % [zone_sauvage.anchor_left, zone_sauvage.anchor_top]):
		return
	print("OK: ZoneJoueur/ZoneSauvage centres sur les 2 zones rondes vert fonce du fond (points reperes dans fondzones.jpeg)")

	var texture_sauvage_impact: TextureRect = ecran.get_node("%TextureSauvage")
	if not _verifier(texture_sauvage_impact.material is ShaderMaterial, "TextureSauvage devrait avoir un ShaderMaterial (flash blanc a l'impact)"):
		return
	var shader_material: ShaderMaterial = texture_sauvage_impact.material
	if not _verifier(shader_material.shader.resource_path == "res://shaders/flash_blanc.gdshader", "TextureSauvage devrait utiliser shaders/flash_blanc.gdshader"):
		return
	if not _verifier(is_equal_approx(float(shader_material.get_shader_parameter("intensite")), 0.0), "intensite du flash devrait etre 0.0 par defaut (pas de flash au repos)"):
		return
	print("OK: structure de l'animation d'impact (ZoneJoueur/ZoneSauvage nommes, flash blanc en place sur TextureSauvage)")

	# 12. Sequence de capture (derniere reponse d'un tableau reussi,
	# demande de Mike) : structure des noeuds presente (ZoneCatch +
	# TextureCatch/PlaceholderCatch), cachee par defaut.
	for chemin in ["%ZoneCatch", "%TextureCatch", "%PlaceholderCatch"]:
		if not _verifier(ecran.get_node_or_null(chemin) != null, "noeud manquant dans EcranTableau.tscn: " + chemin):
			return
	var zone_catch_test: Control = ecran.get_node("%ZoneCatch")
	if not _verifier(not zone_catch_test.visible, "ZoneCatch devrait etre cachee par defaut (visible seulement pendant la sequence de capture)"):
		return
	print("OK: structure de la sequence de capture (ZoneCatch/TextureCatch/PlaceholderCatch) en place, cachee par defaut")

	root.remove_child(ecran)
	ecran.free()

	# 11. SpriteUtil : sprite "de dos" (creature du joueur pendant un
	# tableau) - conversion d'id et repli sur la face si le dos manque.
	if not _verifier(SpriteUtil.id_dos("c1") == "cb1", "id_dos('c1') devrait donner 'cb1'"):
		return
	if not _verifier(SpriteUtil.id_dos("c42") == "cb42", "id_dos('c42') devrait donner 'cb42'"):
		return
	# Id bidon garanti sans fichier dos NI face : repli en cascade renvoie null.
	if not _verifier(SpriteUtil.charger_texture_dos_avec_glow("c_bidon_inexistant", false) == null, "charger_texture_dos_avec_glow() devrait etre null si ni le dos ni la face n'existent"):
		return
	print("OK: SpriteUtil - sprite de dos (id_dos + repli sur la face si absent)")

	# 13. SpriteUtil.charger_texture_catch() : Mike a deja depose
	# assets/creatures/catch.gif (converti par convertir_gifs.ps1 en
	# catch.png), donc charger_texture_catch() doit le trouver.
	if not _verifier(SpriteUtil.charger_texture_catch() is Texture2D, "charger_texture_catch() devrait charger catch.png (catch.gif deja depose par Mike)"):
		return
	print("OK: SpriteUtil.charger_texture_catch() charge catch.png (catch.gif deja depose)")

	SaveManager.free()
	print("=== Smoke test Phase 7 : SUCCES ===")
	quit(0)
