extends Button
class_name CarteNiveau
## Bouton d'un niveau dans l'ecran de selection (10 par matiere, + la
## carte "Examen"). Trois etats visuels : verrouille (desactive, style
## grise via le style "disabled" du theme), disponible (style
## rouge/blanc standard du projet), reussi (variante verte, appliquee
## par-dessus au besoin). Le "disabled" natif de Godot ignore deja
## normal/hover/pressed, donc verrouille n'a besoin d'aucune bascule de
## style supplementaire.
##
## Carte "Examen" (Phase 8, 11e niveau) : meme composant, juste un texte
## different (pas de numero) et une icone optionnelle dans le coin
## superieur droit (afficher_icone_coin()) — voir selection_niveau.gd.

signal choisi(numero: int)

@export var style_reussi_normal: StyleBoxFlat
@export var style_reussi_hover: StyleBoxFlat
@export var style_reussi_pressed: StyleBoxFlat

var _numero: int = 0
var _pressed_connecte: bool = false

func _ready() -> void:
	_connecter_bouton()

## etat : "verrouille" | "disponible" | "reussi". "total" = nombre de
## questions de l'essai enregistre comme "meilleur_score" (toujours 10
## pour un niveau normal ; variable pour l'examen, voir SaveManager).
func configurer(numero: int, nom: String, etat: String, meilleur_score: int, total: int = 10) -> void:
	_numero = numero
	_connecter_bouton()

	match etat:
		"verrouille":
			disabled = true
			text = "Niveau %d\n%s\n(verrouille)" % [numero, nom]
		"reussi":
			disabled = false
			text = "Niveau %d\n%s\nMeilleur score : %d/%d" % [numero, nom, meilleur_score, total]
			if style_reussi_normal != null:
				add_theme_stylebox_override("normal", style_reussi_normal)
				add_theme_stylebox_override("hover", style_reussi_hover)
				add_theme_stylebox_override("pressed", style_reussi_pressed)
		_:
			disabled = false
			text = "Niveau %d\n%s" % [numero, nom]

## Variante "Examen" de configurer() : pas de numero affiche, textes
## adaptes. "disponible" reutilise le meme etat/logique que les niveaux
## normaux (verrouille/disponible/reussi).
func configurer_examen(etat: String, meilleur_score: int, total: int) -> void:
	_numero = 0
	_connecter_bouton()

	match etat:
		"verrouille":
			disabled = true
			text = "Examen\n(termine au moins\nle niveau 1 pour le debloquer)"
		"reussi":
			disabled = false
			text = "Examen\nMeilleur score : %d/%d" % [meilleur_score, total]
			if style_reussi_normal != null:
				add_theme_stylebox_override("normal", style_reussi_normal)
				add_theme_stylebox_override("hover", style_reussi_hover)
				add_theme_stylebox_override("pressed", style_reussi_pressed)
		_:
			disabled = false
			text = "Examen\nToutes tes erreurs, regroupees !"

## Icone decorative dans le coin superieur droit (carte "Examen"
## seulement pour l'instant). Cache le noeud si "texture" est null (pas
## encore depose par Mike, voir ExamenAssetUtil).
func afficher_icone_coin(texture: Texture2D) -> void:
	var icone: TextureRect = %IconeCoin
	icone.texture = texture
	icone.visible = texture != null

func _connecter_bouton() -> void:
	if _pressed_connecte:
		return
	pressed.connect(func(): choisi.emit(_numero))
	_pressed_connecte = true
