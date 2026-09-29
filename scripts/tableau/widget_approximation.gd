extends Control
## Widget "approximation".
## Resout %Nom a la demande (voir widget_pair_impair.gd pour le pourquoi).
##
## 2 formats de question coexistent :
## - Ancien (champ numerique) : { "texte": String, "min": int, "max": int }
##   -> reponse acceptee dans une plage (pas une valeur exacte).
## - Niveau 1 (combat de types, demande de Mike, triangle inspire des
##   faiblesses Pokemon, meme table que data/types.json : eau bat feu,
##   feu bat feuille, feuille bat eau) :
##   { "type_a": String, "type_b": String, "gagnant": String } -> affiche
##   une creature au hasard de chaque type (voir CREATURES_PAR_TYPE, liste
##   fournie par Mike) au-dessus de chaque bouton, colore le bouton selon
##   le type (bleu=eau, rouge=feu, vert=feuille), le joueur clique sur
##   celui qui gagne. "gagnant" est fige dans les donnees (pas de lookup
##   runtime dans data/types.json).

signal reponse_donnee(correcte: bool)

## Liste fournie par Mike (id de creature -> type). Une creature est
## tiree au hasard dans la liste du type concerne a chaque question, pour
## varier l'illustration meme quand le meme type revient plusieurs fois.
const CREATURES_PAR_TYPE := {
	"feuille": [1, 43, 46, 69, 102, 114],
	"feu": [4, 37, 58, 77, 126, 136, 146],
	"eau": [7, 54, 60, 72, 79, 86, 90, 98, 116, 118, 120, 129, 131, 134, 138, 140],
}

const COULEURS_TYPE := {
	"eau": Color(0.2, 0.45, 0.85, 1),
	"feu": Color(0.85, 0.25, 0.15, 1),
	"feuille": Color(0.2, 0.65, 0.25, 1),
}

var _min: int = 0
var _max: int = 0
var _connecte: bool = false
var _mode_combat: bool = false
var _reponse_attendue_combat: String = ""
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_connecter()
	_rng.randomize()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	_mode_combat = question.has("type_a") and question.has("type_b")

	var label_texte: Label = %LabelTexte
	var hbox_saisie: HBoxContainer = %HBoxSaisie
	var hbox_combat: HBoxContainer = %HBoxCombat

	hbox_saisie.visible = not _mode_combat
	hbox_combat.visible = _mode_combat

	if _mode_combat:
		var type_a := String(question.get("type_a", ""))
		var type_b := String(question.get("type_b", ""))
		_reponse_attendue_combat = String(question.get("gagnant", ""))
		label_texte.text = "Qui gagne le combat ?"
		_configurer_cote(%BoutonTypeA, %TextureCreatureA, type_a)
		_configurer_cote(%BoutonTypeB, %TextureCreatureB, type_b)
	else:
		label_texte.text = String(question.get("texte", ""))
		_min = int(question.get("min", 0))
		_max = int(question.get("max", 0))
		var champ_reponse: LineEdit = %ChampReponse
		var bouton_valider: Button = %BoutonValider
		champ_reponse.text = ""
		champ_reponse.editable = true
		bouton_valider.disabled = false

## Configure UN cote du combat : texte/couleur du bouton (type) + image
## d'une creature au hasard de ce type.
func _configurer_cote(bouton: Button, texture_creature: TextureRectAnime, type_id: String) -> void:
	bouton.text = type_id.capitalize()
	bouton.disabled = false
	var couleur: Color = COULEURS_TYPE.get(type_id, Color(0.5, 0.5, 0.5, 1))
	var style := StyleBoxFlat.new()
	style.bg_color = couleur
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	bouton.add_theme_stylebox_override("normal", style)
	bouton.add_theme_stylebox_override("hover", style)
	bouton.add_theme_stylebox_override("pressed", style)
	bouton.add_theme_stylebox_override("disabled", style)
	bouton.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 1))

	var ids: Array = CREATURES_PAR_TYPE.get(type_id, [])
	if ids.is_empty():
		texture_creature.configurer_animation(null, 1)
		return
	var creature_id := "c%d" % ids[_rng.randi_range(0, ids.size() - 1)]
	var texture := SpriteUtil.charger_texture(creature_id)
	texture_creature.configurer_animation(texture, SpriteUtil.compter_frames(texture))

func _connecter() -> void:
	if _connecte:
		return
	var champ_reponse: LineEdit = %ChampReponse
	var bouton_valider: Button = %BoutonValider
	bouton_valider.pressed.connect(_valider)
	champ_reponse.text_submitted.connect(func(_t): _valider())
	var bouton_a: Button = %BoutonTypeA
	var bouton_b: Button = %BoutonTypeB
	bouton_a.pressed.connect(func(): _repondre_combat(bouton_a.text))
	bouton_b.pressed.connect(func(): _repondre_combat(bouton_b.text))
	_connecte = true

func _valider() -> void:
	var champ_reponse: LineEdit = %ChampReponse
	if not champ_reponse.text.is_valid_int():
		return
	var valeur := int(champ_reponse.text)
	champ_reponse.editable = false
	var bouton_valider: Button = %BoutonValider
	bouton_valider.disabled = true
	reponse_donnee.emit(valeur >= _min and valeur <= _max)

func _repondre_combat(texte_bouton: String) -> void:
	var bouton_a: Button = %BoutonTypeA
	var bouton_b: Button = %BoutonTypeB
	bouton_a.disabled = true
	bouton_b.disabled = true
	reponse_donnee.emit(texte_bouton.to_lower() == _reponse_attendue_combat.to_lower())
