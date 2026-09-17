extends Control
## Ecran-titre. Fond et logo sont entierement remplacables par Mike via
## assets/ui/menu/ (voir assets/ui/menu/LISEZ-MOI.txt et MenuAssetUtil) :
## tant que les fichiers n'existent pas, des placeholders generiques
## s'affichent a la meme position/taille.

@onready var texture_fond: TextureRect = %TextureFond
@onready var placeholder_fond: ColorRect = %PlaceholderFond
@onready var texture_logo: TextureRect = %TextureLogo
@onready var placeholder_logo: PanelContainer = %PlaceholderLogo

@onready var bouton_nouvelle_partie: Button = %BoutonNouvellePartie
@onready var bouton_continuer: Button = %BoutonContinuer
@onready var bouton_quitter: Button = %BoutonQuitter

func _ready() -> void:
	_charger_fond()
	_charger_logo()

	bouton_continuer.disabled = not SaveManager.has_save()
	bouton_nouvelle_partie.pressed.connect(_on_nouvelle_partie)
	bouton_continuer.pressed.connect(_on_continuer)
	bouton_quitter.pressed.connect(_on_quitter)

func _charger_fond() -> void:
	var texture := MenuAssetUtil.charger_fond()
	if texture != null:
		texture_fond.texture = texture
		texture_fond.visible = true
		placeholder_fond.visible = false
	else:
		texture_fond.visible = false
		placeholder_fond.visible = true

func _charger_logo() -> void:
	var texture := MenuAssetUtil.charger_logo()
	if texture != null:
		texture_logo.texture = texture
		texture_logo.visible = true
		placeholder_logo.visible = false
	else:
		texture_logo.visible = false
		placeholder_logo.visible = true

func _on_nouvelle_partie() -> void:
	get_tree().change_scene_to_file("res://scenes/DialogueIntro.tscn")

func _on_continuer() -> void:
	SaveManager.load_game()
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")

func _on_quitter() -> void:
	get_tree().quit()
