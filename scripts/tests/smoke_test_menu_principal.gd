extends SceneTree
## Test de fumee headless pour l'ecran-titre restyle (assets remplacables
## + 3 boutons cliquables). Pas execute en jeu normal.
## Lance avec : godot --headless --script res://scripts/tests/smoke_test_menu_principal.gd
##
## N'utilise jamais assert() (bloque indefiniment sans debugger attache).

func _verifier(condition: bool, message: String) -> bool:
	if not condition:
		print("ECHEC: " + message)
		quit(1)
	return condition

func _initialize() -> void:
	print("=== Smoke test ecran-titre (MenuPrincipal) ===")

	# 1. MenuAssetUtil doit retourner null tant qu'aucun asset n'est depose
	#    (aucun fond_menu.png / logo_menu.png dans assets/ui/menu/ pour l'instant).
	if not _verifier(MenuAssetUtil.charger_fond() == null, "charger_fond() devrait etre null (aucun fond_menu.png depose)"):
		return
	if not _verifier(MenuAssetUtil.charger_logo() == null, "charger_logo() devrait etre null (aucun logo_menu.png depose)"):
		return
	if not _verifier(MenuAssetUtil.charger_video_fond() == null, "charger_video_fond() devrait etre null (aucun fond_menu.ogv depose)"):
		return
	print("OK: MenuAssetUtil retourne null tant qu'aucun asset n'est depose")

	# 2. Instancie la scene MenuPrincipal et verifie les valeurs PAR DEFAUT
	#    (telles qu'ecrites dans le .tscn, AVANT execution de _ready()).
	#    Note : menu_principal.gd reference l'autoload SaveManager par son
	#    nom global, ce qui ne compile pas sous --script (meme piege que
	#    documente en Phase 2/3 : "Identifier not found"). On ne peut donc
	#    pas executer _ready() ici ; le comportement runtime complet
	#    (fond/logo/boutons apres _ready, "Continuer" desactive sans
	#    sauvegarde) est couvert par le boot headless reel
	#    (godot --headless --path <projet>, sans --script), qui charge les
	#    autoloads normalement et doit rester a 0 erreur stderr.
	var MenuScene := preload("res://scenes/MenuPrincipal.tscn")
	var menu = MenuScene.instantiate()
	root.add_child(menu)

	var placeholder_fond: ColorRect = menu.get_node("%PlaceholderFond")
	var texture_fond: TextureRect = menu.get_node("%TextureFond")
	if not _verifier(placeholder_fond.visible and not texture_fond.visible, "placeholder de fond devrait etre visible par defaut dans le .tscn"):
		return
	print("OK: placeholder de fond visible par defaut, texture de fond cachee par defaut")

	var video_fond: VideoStreamPlayer = menu.get_node("%VideoFond")
	if not _verifier(video_fond != null and not video_fond.visible, "VideoFond devrait exister et etre cache par defaut dans le .tscn"):
		return
	print("OK: VideoFond existe et est cache par defaut (fond video optionnel, Phase 8)")

	var placeholder_logo = menu.get_node("%PlaceholderLogo")
	var texture_logo: TextureRect = menu.get_node("%TextureLogo")
	if not _verifier(placeholder_logo.visible and not texture_logo.visible, "placeholder de logo devrait etre visible par defaut dans le .tscn"):
		return
	print("OK: placeholder de logo visible par defaut, texture de logo cachee par defaut")

	# 3. Verifie que les 3 boutons existent (structure de la scene).
	var bouton_nouvelle_partie: Button = menu.get_node("%BoutonNouvellePartie")
	var bouton_continuer: Button = menu.get_node("%BoutonContinuer")
	var bouton_quitter: Button = menu.get_node("%BoutonQuitter")
	if not _verifier(bouton_nouvelle_partie != null and bouton_continuer != null and bouton_quitter != null, "un des 3 boutons du menu est introuvable"):
		return
	print("OK: les 3 boutons (Nouvelle partie / Continuer / Quitter) existent dans la scene")

	root.remove_child(menu)
	menu.free()

	print("=== Smoke test ecran-titre : SUCCES ===")
	quit(0)
