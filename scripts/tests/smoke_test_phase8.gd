extends SceneTree
## Test de fumee headless pour la Phase 8 (polish) : migration des
## sprites de creatures PNG statique -> GIF anime (planche PNG generee
## par scripts/tools/convertir_gifs.ps1 + SpriteUtil.compter_frames() +
## TextureRectAnime), les 2 nouvelles zones de decor du Hub, et le son
## de clic centralise (AudioManager branche automatiquement tout
## BaseButton via SceneTree.node_added). Pas execute en jeu normal.
## Lance avec :
## godot --headless --script res://scripts/tests/smoke_test_phase8.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _texture_factice(largeur: int, hauteur: int) -> ImageTexture:
	var image := Image.create(largeur, hauteur, false, Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(image)

func _initialize() -> void:
	print("=== Smoke test Phase 8 (GIF creatures + decor Hub) ===")

	# 1. SpriteUtil.compter_frames() : deduit le nombre de frames d'une
	# planche a partir de ses seules dimensions (chaque frame carree).
	if not _verifier(SpriteUtil.compter_frames(null) == 1, "compter_frames(null) devrait etre 1"):
		return
	if not _verifier(SpriteUtil.compter_frames(_texture_factice(64, 64)) == 1, "planche carree 64x64 -> 1 frame"):
		return
	if not _verifier(SpriteUtil.compter_frames(_texture_factice(128, 64)) == 2, "planche 128x64 -> 2 frames de 64x64"):
		return
	if not _verifier(SpriteUtil.compter_frames(_texture_factice(320, 64)) == 5, "planche 320x64 -> 5 frames de 64x64"):
		return
	print("OK: SpriteUtil.compter_frames() deduit correctement le nombre de frames")

	# 2. TextureRectAnime : reste statique si nb_frames <= 1 (pas de
	# Timer cree), s'anime sinon (Timer cree + AtlasTexture qui avance
	# region par region a chaque frame_suivante()).
	var rect := TextureRectAnime.new()
	root.add_child(rect)
	# Timer.start() exige d'etre dans l'arbre de scene, et l'entree dans
	# l'arbre n'est effective qu'a partir de la frame suivante (meme
	# piege de timing que documente pour @onready en Phase 3/6).
	await process_frame
	var feuille_statique := _texture_factice(64, 64)
	rect.configurer_animation(feuille_statique, 1)
	if not _verifier(rect.texture == feuille_statique, "nb_frames<=1 devrait afficher la texture telle quelle, sans AtlasTexture"):
		return
	if not _verifier(rect.get_child_count() == 0, "nb_frames<=1 ne devrait creer aucun Timer"):
		return
	print("OK: TextureRectAnime reste statique quand nb_frames <= 1")

	var feuille_animee := _texture_factice(192, 64)  # 3 frames de 64x64
	rect.configurer_animation(feuille_animee, 3, 10.0)
	if not _verifier(rect.get_child_count() == 1, "nb_frames>1 devrait creer un Timer"):
		return
	var minuteur: Timer = rect.get_child(0)
	if not _verifier(minuteur.time_left > 0.0 or not minuteur.is_stopped(), "le Timer d'animation devrait etre demarre"):
		return
	var atlas: AtlasTexture = rect.texture
	if not _verifier(atlas != null and atlas.region == Rect2(0, 0, 64, 64), "1ere frame affichee devrait etre la region (0,0,64,64)"):
		return
	rect._frame_suivante()
	atlas = rect.texture
	if not _verifier(atlas.region == Rect2(64, 0, 64, 64), "2e frame devrait etre la region (64,0,64,64)"):
		return
	rect._frame_suivante()
	rect._frame_suivante()  # 3e frame -> reboucle a la 1ere (3 frames au total)
	atlas = rect.texture
	if not _verifier(atlas.region == Rect2(0, 0, 64, 64), "l'animation devrait reboucler apres la derniere frame"):
		return
	root.remove_child(rect)
	rect.free()
	print("OK: TextureRectAnime cree un Timer et fait avancer/reboucler les frames correctement")

	# 2b. TextureRectAnime.configurer_animation_unique() (Phase 8, sequence
	# de capture) : joue UNE SEULE FOIS, se fige sur la DERNIERE frame
	# (jamais de reboucle a la frame 0) et emet "animation_terminee".
	var rect_unique := TextureRectAnime.new()
	root.add_child(rect_unique)
	await process_frame
	var feuille_catch := _texture_factice(192, 64)  # 3 frames de 64x64
	# Array plutot qu'un bool local : un lambda GDScript capture une
	# variable locale PAR VALEUR (snapshot), pas par reference -- ecrire
	# dedans depuis le callback ne serait pas visible ici pour un bool.
	# Un Array (type reference) contourne ca.
	var termine := [false]
	rect_unique.animation_terminee.connect(func(): termine[0] = true)
	rect_unique.configurer_animation_unique(feuille_catch, 3, 10.0)
	rect_unique._frame_suivante()  # -> frame 2
	rect_unique._frame_suivante()  # -> frame 3 (derniere), devrait se figer + emettre
	var atlas_unique: AtlasTexture = rect_unique.texture
	if not _verifier(atlas_unique.region == Rect2(128, 0, 64, 64), "configurer_animation_unique() devrait se figer sur la derniere frame (region 128,0,64,64), obtenu %s" % atlas_unique.region):
		return
	if not _verifier(termine[0], "configurer_animation_unique() devrait emettre animation_terminee une fois la derniere frame atteinte"):
		return
	rect_unique._frame_suivante()  # un appel de plus ne devrait PAS reboucler
	atlas_unique = rect_unique.texture
	if not _verifier(atlas_unique.region == Rect2(128, 0, 64, 64), "configurer_animation_unique() ne devrait jamais reboucler (clamp sur la derniere frame)"):
		return
	root.remove_child(rect_unique)
	rect_unique.free()
	print("OK: TextureRectAnime.configurer_animation_unique() - joue une fois, se fige sur la derniere frame (clamp), emet animation_terminee")

	# 3. HubAssetUtil : null tant qu'aucun fichier n'est depose
	# (assets/ui/hub/gauche.png).
	if not _verifier(HubAssetUtil.charger_gauche() == null, "charger_gauche() devrait etre null (aucun gauche.png depose)"):
		return
	print("OK: HubAssetUtil retourne null tant qu'aucun asset n'est depose")

	# 4. Structure de Hub.tscn : les 2 nouvelles zones de decor sont
	# presentes, textures cachees et placeholders visibles par defaut
	# (le script racine ne compile pas sous --script, meme limite
	# documentee depuis la Phase 2 -- la structure des noeuds reste
	# verifiable sans executer _ready()).
	var HubScene := preload("res://scenes/Hub.tscn")
	var hub = HubScene.instantiate()
	root.add_child(hub)

	var texture_gauche: TextureRect = hub.get_node_or_null("%TextureGauche")
	var placeholder_gauche: ColorRect = hub.get_node_or_null("%PlaceholderGauche")
	var texture_droite: TextureRect = hub.get_node_or_null("%TextureDroite")
	var placeholder_droite: ColorRect = hub.get_node_or_null("%PlaceholderDroite")
	if not _verifier(texture_gauche != null and placeholder_gauche != null and texture_droite != null and placeholder_droite != null, "un des noeuds de decor du Hub est introuvable"):
		return
	if not _verifier(not texture_gauche.visible and placeholder_gauche.visible, "zone gauche : placeholder visible par defaut dans le .tscn"):
		return
	if not _verifier(not texture_droite.visible and placeholder_droite.visible, "zone droite : placeholder visible par defaut dans le .tscn"):
		return
	root.remove_child(hub)
	hub.free()
	print("OK: Hub.tscn a bien ses 2 zones de decor (gauche/droite), placeholders visibles par defaut")

	# 5. AudioManager : le son de clic se branche automatiquement sur
	# TOUT BaseButton qui entre dans l'arbre (_sur_noeud_ajoute), sans
	# avoir besoin d'etre reellement ajoute a un arbre de scene pour
	# tester la logique de connexion elle-meme.
	var AudioManagerScript := preload("res://scripts/autoload/audio_manager.gd")
	var audio_manager = AudioManagerScript.new()
	var bouton := Button.new()
	if not _verifier(bouton.button_down.get_connections().is_empty(), "un Button neuf ne devrait avoir aucune connexion sur button_down"):
		return
	audio_manager._sur_noeud_ajoute(bouton)
	var trouve := false
	for connexion in bouton.button_down.get_connections():
		if connexion["callable"] == Callable(audio_manager, "jouer_clic"):
			trouve = true
	if not _verifier(trouve, "_sur_noeud_ajoute() devrait connecter button_down -> jouer_clic() pour un BaseButton"):
		return
	print("OK: AudioManager connecte automatiquement button_down -> jouer_clic() pour tout BaseButton")

	var control := Control.new()
	audio_manager._sur_noeud_ajoute(control)  # ne doit pas planter, rien a connecter
	print("OK: _sur_noeud_ajoute() ignore sans erreur les noeuds qui ne sont pas des BaseButton")

	bouton.free()
	control.free()
	audio_manager.free()

	print("=== Smoke test Phase 8 : SUCCES ===")
	quit(0)
