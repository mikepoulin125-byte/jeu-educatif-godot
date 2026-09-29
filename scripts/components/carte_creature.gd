extends PanelContainer
## Carte reutilisable affichant une creature (sprite reel ou placeholder,
## nom, description) avec un bouton de selection.
##
## configurer() peut etre appelee juste apres instantiate(), avant meme
## add_child() : on resout les noeuds enfants via %Nom a chaque appel
## plutot que de les mettre en cache dans des @onready, car @onready
## n'est peuple qu'au moment ou _ready() se declenche - qui peut etre
## differe (par ex. dans un contexte headless sans boucle de frame),
## alors que la resolution %Nom fonctionne des l'instanciation.

signal choisie(creature_id: String)

var _creature_id: String = ""
var _pressed_connecte: bool = false

func _ready() -> void:
	_connecter_bouton()

func configurer(creature_id: String, creature_data: Dictionary) -> void:
	_creature_id = creature_id
	_connecter_bouton()

	var forms: Dictionary = creature_data.get("forms", {})
	var names: Dictionary = creature_data.get("names", {})
	var sprite_id: String = forms.get("stage1", "")

	var texture_rect: TextureRectAnime = %TextureSprite
	var placeholder: ColorRect = %PlaceholderSprite
	var label_placeholder: Label = %LabelPlaceholder

	var texture := SpriteUtil.charger_texture(sprite_id)
	if texture != null:
		texture_rect.configurer_animation(texture, SpriteUtil.compter_frames(texture))
		texture_rect.visible = true
		placeholder.visible = false
	else:
		texture_rect.visible = false
		placeholder.visible = true
		label_placeholder.text = sprite_id if not sprite_id.is_empty() else "?"

	var label_nom: Label = %LabelNom
	var label_description: Label = %LabelDescription
	label_nom.text = String(names.get("stage1", _creature_id))
	label_description.text = String(creature_data.get("description", ""))

func _connecter_bouton() -> void:
	if _pressed_connecte:
		return
	var bouton_choisir: Button = %BoutonChoisir
	bouton_choisir.pressed.connect(func(): choisie.emit(_creature_id))
	_pressed_connecte = true
