extends Control
## Ecran-titre. Fond et logo sont entierement remplacables par Mike via
## assets/ui/menu/ (voir assets/ui/menu/LISEZ-MOI.txt et MenuAssetUtil) :
## tant que les fichiers n'existent pas, des placeholders generiques
## s'affichent a la meme position/taille.

@onready var texture_fond: TextureRect = %TextureFond
@onready var placeholder_fond: ColorRect = %PlaceholderFond
@onready var video_fond: VideoStreamPlayer = %VideoFond
@onready var texture_logo: TextureRect = %TextureLogo
@onready var placeholder_logo: PanelContainer = %PlaceholderLogo

@onready var bouton_nouvelle_partie: Button = %BoutonNouvellePartie
@onready var bouton_continuer: Button = %BoutonContinuer
@onready var bouton_quitter: Button = %BoutonQuitter

func _ready() -> void:
	video_fond.finished.connect(video_fond.play)
	_charger_fond()
	_charger_logo()
	AudioManager.jouer_musique(AudioManager.MUSIQUE_TITRE)

	bouton_continuer.disabled = not SaveManager.has_save()
	bouton_nouvelle_partie.pressed.connect(_on_nouvelle_partie)
	bouton_continuer.pressed.connect(_on_continuer)
	bouton_quitter.pressed.connect(_on_quitter)

## Fond video (fond_menu.ogv) prioritaire sur l'image fixe (fond_menu.png)
## si les deux sont presents. Plein ecran, derriere ZoneLogo/ZoneBoutons
## (ordre des noeuds) et mouse_filter=ignore, donc ne bloque jamais les
## elements de menu par-dessus.
func _charger_fond() -> void:
	var video := MenuAssetUtil.charger_video_fond()
	if video != null:
		video_fond.stream = video
		video_fond.visible = true
		video_fond.play()
		texture_fond.visible = false
		placeholder_fond.visible = false
		return
	video_fond.visible = false

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
	_lancer_avec_ecran_de_chargement("res://scenes/DialogueIntro.tscn")

func _on_continuer() -> void:
	SaveManager.load_game()
	_lancer_avec_ecran_de_chargement("res://scenes/Hub.tscn")

func _on_quitter() -> void:
	get_tree().quit()

## Passage par EcranChargement.tscn (faux temps de chargement de 5s, voir
## section 4 de la demande de Mike) avant d'arriver sur scene_cible. Le
## fondu au blanc lui-meme est gere par SceneTransition (meme sequence
## que toutes les autres transitions du jeu).
func _lancer_avec_ecran_de_chargement(scene_cible: String) -> void:
	bouton_nouvelle_partie.disabled = true
	bouton_continuer.disabled = true
	bouton_quitter.disabled = true

	GameState.scene_suivante = scene_cible
	SceneTransition.changer_scene("res://scenes/EcranChargement.tscn")
