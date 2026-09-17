extends PanelContainer
## Carte reutilisable affichant une creature (sprite reel ou placeholder,
## nom, description) avec un bouton de selection.
##
## configurer() peut etre appelee juste apres instantiate()+add_child(),
## avant que _ready() (et donc les @onready) ne soit passe : on met la
## donnee en attente et on l'applique des que le noeud est pret.

signal choisie(creature_id: String)

@onready var texture_rect: TextureRect = %TextureSprite
@onready var placeholder: ColorRect = %PlaceholderSprite
@onready var label_placeholder: Label = %LabelPlaceholder
@onready var label_nom: Label = %LabelNom
@onready var label_description: Label = %LabelDescription
@onready var bouton_choisir: Button = %BoutonChoisir

var _creature_id: String = ""
var _donnee_en_attente: Dictionary = {}
var _a_une_donnee_en_attente: bool = false

func _ready() -> void:
	bouton_choisir.pressed.connect(func(): choisie.emit(_creature_id))
	if _a_une_donnee_en_attente:
		_appliquer(_donnee_en_attente)
		_a_une_donnee_en_attente = false

func configurer(creature_id: String, creature_data: Dictionary) -> void:
	_creature_id = creature_id
	if is_node_ready():
		_appliquer(creature_data)
	else:
		_donnee_en_attente = creature_data
		_a_une_donnee_en_attente = true

func _appliquer(creature_data: Dictionary) -> void:
	var forms: Dictionary = creature_data.get("forms", {})
	var names: Dictionary = creature_data.get("names", {})
	var sprite_id: String = forms.get("stage1", "")

	var texture := SpriteUtil.charger_texture(sprite_id)
	if texture != null:
		texture_rect.texture = texture
		texture_rect.visible = true
		placeholder.visible = false
	else:
		texture_rect.visible = false
		placeholder.visible = true
		label_placeholder.text = sprite_id if not sprite_id.is_empty() else "?"

	label_nom.text = String(names.get("stage1", _creature_id))
	label_description.text = String(creature_data.get("description", ""))
