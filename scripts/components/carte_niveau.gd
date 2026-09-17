extends Button
class_name CarteNiveau
## Bouton d'un niveau dans l'ecran de selection (10 par matiere). Trois
## etats visuels : verrouille (desactive, style grise via le style
## "disabled" du theme), disponible (style rouge/blanc standard du
## projet), reussi (variante verte, appliquee par-dessus au besoin).
## Le "disabled" natif de Godot ignore deja normal/hover/pressed, donc
## verrouille n'a besoin d'aucune bascule de style supplementaire.

signal choisi(numero: int)

@export var style_reussi_normal: StyleBoxFlat
@export var style_reussi_hover: StyleBoxFlat
@export var style_reussi_pressed: StyleBoxFlat

var _numero: int = 0
var _pressed_connecte: bool = false

func _ready() -> void:
	_connecter_bouton()

## etat : "verrouille" | "disponible" | "reussi"
func configurer(numero: int, nom: String, etat: String, meilleur_score: int) -> void:
	_numero = numero
	_connecter_bouton()

	match etat:
		"verrouille":
			disabled = true
			text = "Niveau %d\n%s\n(verrouille)" % [numero, nom]
		"reussi":
			disabled = false
			text = "Niveau %d\n%s\nMeilleur score : %d/10" % [numero, nom, meilleur_score]
			if style_reussi_normal != null:
				add_theme_stylebox_override("normal", style_reussi_normal)
				add_theme_stylebox_override("hover", style_reussi_hover)
				add_theme_stylebox_override("pressed", style_reussi_pressed)
		_:
			disabled = false
			text = "Niveau %d\n%s" % [numero, nom]

func _connecter_bouton() -> void:
	if _pressed_connecte:
		return
	pressed.connect(func(): choisi.emit(_numero))
	_pressed_connecte = true
