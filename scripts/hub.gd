extends Control
## Hub principal (section 6 de la spec) : 8 badges de matiere, XP total
## permanent en haut-gauche, bouton Roster permanent.
##
## Phase 8 : deux zones de decor flanquent la grille de matieres,
## centrees verticalement dans leur moitie d'ecran respective.
## - Gauche : contenu pas encore determine par Mike, seul l'emplacement
##   + le mecanisme de chargement sont en place (voir HubAssetUtil et
##   assets/ui/hub/LISEZ-MOI.txt).
## - Droite : la creature principale actuelle du joueur (celle choisie
##   via "Accompagne-moi !" au Roster), meme resolution de sprite que
##   partout ailleurs dans le jeu (SpriteUtil + SaveManager).

const CarteMatiereScene := preload("res://scenes/components/CarteMatiere.tscn")

@onready var label_xp: Label = %LabelXp
@onready var grille_matieres: GridContainer = %GrilleMatieres
@onready var bouton_roster: Button = %BoutonRoster
@onready var texture_gauche: TextureRectAnime = %TextureGauche
@onready var placeholder_gauche: ColorRect = %PlaceholderGauche
@onready var texture_droite: TextureRectAnime = %TextureDroite
@onready var placeholder_droite: ColorRect = %PlaceholderDroite

func _ready() -> void:
	_actualiser_xp()
	bouton_roster.pressed.connect(_on_roster_presse)
	_peupler_matieres()
	_afficher_zone_gauche()
	_afficher_creature_principale()
	AudioManager.jouer_musique(AudioManager.MUSIQUE_HUB)

func _afficher_zone_gauche() -> void:
	var texture := HubAssetUtil.charger_gauche()
	if texture != null:
		texture_gauche.configurer_animation(texture, SpriteUtil.compter_frames(texture))
		texture_gauche.visible = true
		placeholder_gauche.visible = false
	else:
		texture_gauche.visible = false
		placeholder_gauche.visible = true

func _afficher_creature_principale() -> void:
	var creature_id: String = SaveManager.get_creature_principale_id()
	if creature_id.is_empty() or not DataManager.creatures.has(creature_id):
		return
	var creature_data: Dictionary = DataManager.creatures[creature_id]
	var stage := SaveManager.get_stage_creature(creature_id)
	var forms: Dictionary = creature_data.get("forms", {})
	var sprite_id: String = String(forms.get("stage%d" % stage, ""))
	var est_glow := SaveManager.est_glow_creature(creature_id)

	var texture := SpriteUtil.charger_texture_avec_glow(sprite_id, est_glow)
	if texture != null:
		texture_droite.configurer_animation(texture, SpriteUtil.compter_frames(texture))
		texture_droite.visible = true
		placeholder_droite.visible = false

func _actualiser_xp() -> void:
	label_xp.text = "XP : %d" % SaveManager.get_xp_total()

func _peupler_matieres() -> void:
	for matiere in DataManager.matieres:
		var carte := CarteMatiereScene.instantiate()
		grille_matieres.add_child(carte)
		carte.configurer(matiere)
		carte.choisie.connect(_on_matiere_choisie)

func _on_matiere_choisie(matiere_id: String) -> void:
	GameState.matiere_courante_id = matiere_id
	# Phase 5 construira le vrai ecran de selection de niveau ; en
	# attendant, un placeholder minimal confirme que la navigation fonctionne.
	SceneTransition.changer_scene("res://scenes/SelectionNiveau.tscn")

func _on_roster_presse() -> void:
	# Phase 4 construira le vrai ecran Roster ; placeholder minimal pour l'instant.
	SceneTransition.changer_scene("res://scenes/Roster.tscn")
