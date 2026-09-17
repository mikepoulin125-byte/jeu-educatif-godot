extends Control
## Ecran de chargement factice (5 secondes fixes, meme si le vrai
## chargement est instantane) entre le menu et l'arrivee dans le jeu.
## Icone remplacable par Mike (assets/ui/chargement/, voir
## ChargementAssetUtil) tournant en continu (1 tour / 2s), et 3 points
## qui rebondissent en vague (voir AnimMathUtil pour le detail des
## formules, testees separement sans avoir besoin de faire tourner cette
## scene).

const DUREE_CHARGEMENT := 5.0
const SCENE_PAR_DEFAUT := "res://scenes/Hub.tscn"

@onready var zone_rotation: Control = %ZoneRotation
@onready var texture_icone: TextureRect = %TextureIcone
@onready var placeholder_icone: Control = %PlaceholderIcone
@onready var point0: Control = %Point0
@onready var point1: Control = %Point1
@onready var point2: Control = %Point2
@onready var timer: Timer = %Timer

var _temps: float = 0.0
var _y_base_points: float = 0.0

func _ready() -> void:
	_charger_icone()

	zone_rotation.pivot_offset = zone_rotation.size / 2.0
	_y_base_points = point0.position.y

	timer.wait_time = DUREE_CHARGEMENT
	timer.one_shot = true
	timer.timeout.connect(_terminer)
	timer.start()

func _process(delta: float) -> void:
	_temps += delta
	zone_rotation.rotation = AnimMathUtil.rotation_apres(_temps)
	point0.position.y = _y_base_points + AnimMathUtil.decalage_point_chargement(_temps, 0)
	point1.position.y = _y_base_points + AnimMathUtil.decalage_point_chargement(_temps, 1)
	point2.position.y = _y_base_points + AnimMathUtil.decalage_point_chargement(_temps, 2)

func _charger_icone() -> void:
	var texture := ChargementAssetUtil.charger_icone()
	if texture != null:
		texture_icone.texture = texture
		texture_icone.visible = true
		placeholder_icone.visible = false
	else:
		texture_icone.visible = false
		placeholder_icone.visible = true

func _terminer() -> void:
	var cible := GameState.scene_suivante
	if cible.is_empty():
		cible = SCENE_PAR_DEFAUT
	get_tree().change_scene_to_file(cible)
