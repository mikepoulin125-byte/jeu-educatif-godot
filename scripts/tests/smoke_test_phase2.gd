extends SceneTree
## Test de fumee headless pour la Phase 2 (pas execute en jeu normal).
## Lance avec : godot --headless --script res://scripts/tests/smoke_test_phase2.gd
## Simule le parcours Menu -> Intro -> Choix starter -> Sauvegarde, sans GUI reelle.
##
## N'utilise jamais assert() : un assert() qui echoue declenche une pause du
## debugger de script, ce qui bloque indefiniment un run --headless sans
## debugger attache. On verifie et on quitte explicitement a la place.

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

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
	if not _verifier(lignes.size() == 4, "attendu 4 lignes d'intro, obtenu %d" % lignes.size()):
		return
	print("OK: intro.json charge (%d lignes)" % lignes.size())

	# 1b. Verifie que le texte d'indice vient aussi de intro.json (rien de
	# code en dur dans dialogue_intro.gd / DialogueIntro.tscn).
	var indice := DataManager.get_texte_indice_intro()
	if not _verifier(not indice.is_empty(), "texte_indice absent de intro.json"):
		return
	print("OK: texte_indice charge depuis intro.json: '%s'" % indice)

	# 2. Verifie les starters.
	var starters := DataManager.get_creatures_starters()
	if not _verifier(starters.size() == 3, "attendu 3 starters, obtenu %d" % starters.size()):
		return
	print("OK: %d creatures starter trouvees: %s" % [starters.size(), str(starters)])

	# 2b. Sprites des starters confirmes par Mike : c1, c4, c7 (stage1 de
	# chaque ligne de creature starter).
	var sprites_starters_attendus := ["c1", "c4", "c7"]
	var sprites_starters_obtenus := []
	for id in starters:
		var forms: Dictionary = DataManager.creatures[id].get("forms", {})
		sprites_starters_obtenus.append(String(forms.get("stage1", "")))
	sprites_starters_obtenus.sort()
	sprites_starters_attendus.sort()
	if not _verifier(sprites_starters_obtenus == sprites_starters_attendus, "sprites des starters attendus %s, obtenu %s" % [sprites_starters_attendus, sprites_starters_obtenus]):
		return
	print("OK: les 3 starters utilisent bien les sprites c1/c4/c7")

	# 3. Instancie une carte pour chaque starter (verifie configurer() ne crashe pas).
	for id in starters:
		var carte = CarteCreatureScene.instantiate()
		root.add_child(carte)
		carte.configurer(id, DataManager.creatures[id])
		var noms: Dictionary = DataManager.creatures[id].get("names", {})
		var nom_attendu: String = String(noms.get("stage1", id))
		var nom_obtenu: String = carte.get_node("%LabelNom").text
		if not _verifier(nom_obtenu == nom_attendu, "nom mal applique pour %s : attendu '%s', obtenu '%s'" % [id, nom_attendu, nom_obtenu]):
			return
		root.remove_child(carte)
		carte.free()
	print("OK: cartes de starter configurees sans erreur")

	# 3b. Sprite reduit de 50% (demande de Mike) dans CarteCreature : le
	# sprite occupe le centre 50%x50% (donc chaque dimension lineaire
	# divisee par 2) de SpriteZone, pas la totalite.
	var carte_taille = CarteCreatureScene.instantiate()
	root.add_child(carte_taille)
	var texture_sprite: TextureRect = carte_taille.get_node("%TextureSprite")
	if not _verifier(is_equal_approx(texture_sprite.anchor_left, 0.25) and is_equal_approx(texture_sprite.anchor_right, 0.75) and is_equal_approx(texture_sprite.anchor_top, 0.25) and is_equal_approx(texture_sprite.anchor_bottom, 0.75), "TextureSprite devrait occuper le centre 50%%x50%% de SpriteZone (creature reduite de 50%%), obtenu anchors (%f,%f,%f,%f)" % [texture_sprite.anchor_left, texture_sprite.anchor_top, texture_sprite.anchor_right, texture_sprite.anchor_bottom]):
		return
	root.remove_child(carte_taille)
	carte_taille.free()
	print("OK: CarteCreature - sprite reduit de 50%% (anchors 0.25-0.75)")

	# 3c. Police Rubik (demande de Mike) appliquee sur l'ecran de choix du
	# starter : LabelTitre (SelectionStarter.tscn) et LabelNom (CarteCreature.tscn).
	var RubikFont := load("res://assets/fonts/Rubik-Bold.ttf")
	var SelectionStarterScene := preload("res://scenes/SelectionStarter.tscn")
	var selection_starter = SelectionStarterScene.instantiate()
	root.add_child(selection_starter)
	var label_titre_starter: Label = selection_starter.get_node("%LabelTitre")
	if not _verifier(label_titre_starter.get_theme_font("font") == RubikFont, "LabelTitre de SelectionStarter.tscn devrait utiliser Rubik-Bold"):
		return
	root.remove_child(selection_starter)
	selection_starter.free()

	var carte_police = CarteCreatureScene.instantiate()
	root.add_child(carte_police)
	var label_nom_carte: Label = carte_police.get_node("%LabelNom")
	if not _verifier(label_nom_carte.get_theme_font("font") == RubikFont, "LabelNom de CarteCreature.tscn devrait utiliser Rubik-Bold"):
		return
	root.remove_child(carte_police)
	carte_police.free()
	print("OK: police Rubik appliquee sur l'ecran de choix du starter (titre + nom des creatures)")

	# 4. Simule le choix d'un starter -> cree la sauvegarde.
	SaveManager.delete_save()
	var choix: String = starters[0]
	SaveManager.new_game(choix)
	if not _verifier(SaveManager.data.get("starter_id") == choix, "starter_id non enregistre"):
		return
	if not _verifier(SaveManager.get_creatures_vues().has(choix), "starter pas dans creatures_vues"):
		return
	if not _verifier(SaveManager.get_creatures_capturees().has(choix), "starter pas dans creatures_capturees"):
		return
	print("OK: SaveManager.new_game('%s') -> sauvegarde correcte" % choix)

	# 5. Verifie que la sauvegarde survit a un reload depuis le disque.
	SaveManager.data = {}
	var charge := SaveManager.load_game()
	if not _verifier(charge, "echec du rechargement de la sauvegarde"):
		return
	if not _verifier(SaveManager.data.get("starter_id") == choix, "starter_id perdu apres reload"):
		return
	print("OK: sauvegarde rechargee depuis le disque")

	SaveManager.delete_save()

	# 6. Fond remplacable de DialogueIntro.tscn (Phase 8, demande de Mike) :
	# structure des noeuds presente (script racine ne compile pas sous
	# --script, meme limite documentee depuis cette meme phase — structure
	# verifiable quand meme). Pas de test "null par defaut" ici : Mike a
	# deja depose son propre assets/ui/dialogue_intro/fond.png en local
	# (meme situation deja documentee pour logo_menu.png/gauche.png/
	# clic_bouton.mp3) — on verifie juste que charger_fond() ne plante
	# pas et renvoie bien un Texture2D des qu'un fichier existe.
	var texture_reelle := DialogueIntroAssetUtil.charger_fond()
	if not _verifier(texture_reelle == null or texture_reelle is Texture2D, "charger_fond() devrait renvoyer null ou un Texture2D, obtenu %s" % typeof(texture_reelle)):
		return
	var DialogueIntroScene := preload("res://scenes/DialogueIntro.tscn")
	var dialogue = DialogueIntroScene.instantiate()
	root.add_child(dialogue)
	for chemin in ["%TextureFond", "%PlaceholderFond", "%LabelDialogue", "%LabelIndice"]:
		if not _verifier(dialogue.get_node_or_null(chemin) != null, "noeud manquant dans DialogueIntro.tscn: " + chemin):
			return
	var placeholder_fond: ColorRect = dialogue.get_node("%PlaceholderFond")
	var texture_fond: TextureRect = dialogue.get_node("%TextureFond")
	if not _verifier(placeholder_fond.visible and not texture_fond.visible, "placeholder de fond devrait etre visible par defaut dans le .tscn (texture cachee)"):
		return
	root.remove_child(dialogue)
	dialogue.free()
	print("OK: DialogueIntro.tscn - fond remplacable en place (placeholder par defaut)")

	DataManager.free()
	SaveManager.free()
	print("=== Smoke test Phase 2 : SUCCES ===")
	quit(0)
