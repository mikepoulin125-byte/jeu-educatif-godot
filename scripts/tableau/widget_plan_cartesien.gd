extends Control
## Widget "plan_cartesien". Le plan est toujours dessine par le meme
## composant partage (PlanCartesienView - axes flesches + quadrillage,
## MEME visuel pour tous les tableaux du badge). Deux types de question
## geres via question["type"] :
## - "completer_axe" (tableaux 1-2) : un axe complet, l'autre vide sauf
##   une graduation en evidence (rond rouge) que l'enfant ecrit.
## - "lire_coordonnees" (tableau 3) : les deux axes sont complets, une
##   creature (meme sprite/GIF que le roster, id 1-151) est placee a un
##   point (x, y) et l'enfant ecrit les deux coordonnees.
## D'autres types (ex. cliquer une intersection) seront ajoutes ici au
## fur et a mesure des prochains tableaux.
##
## Resout %Nom a la demande (voir widget_pair_impair.gd pour le
## pourquoi).

signal reponse_donnee(correcte: bool)

var _reponse_attendue: int = 0
var _x_attendu: int = 0
var _y_attendu: int = 0
var _connecte: bool = false
var _vue_ref: PlanCartesienView
var _zone_creature_ref: Control

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	var type: String = String(question.get("type", "completer_axe"))
	var taille: int = int(question.get("taille_grille", 5))
	var vue: PlanCartesienView = %Vue
	var zone_creature: Control = %ZoneCreature
	var zone_saisie_axe: Control = %ZoneSaisieAxe
	var zone_saisie_coords: Control = %ZoneSaisieCoords
	var label_consigne: Label = %LabelConsigne

	if type == "lire_coordonnees":
		zone_creature.visible = false  # remis a true par _placer_creature() une fois la texture prete
		zone_saisie_axe.visible = false
		zone_saisie_coords.visible = true
		_configurer_lire_coordonnees(question, taille, vue, zone_creature)
		label_consigne.text = "Ecris les coordonnees (X, Y) de la creature."
	else:
		zone_creature.visible = false
		zone_saisie_axe.visible = true
		zone_saisie_coords.visible = false
		_configurer_completer_axe(question, taille, vue)
		var axe: String = String(question.get("axe_manquant", "x"))
		var nom_axe := "X" if axe == "x" else "Y"
		label_consigne.text = "Quel nombre va dans le rond rouge de l'axe des %s ?" % nom_axe

func _configurer_completer_axe(question: Dictionary, taille: int, vue: PlanCartesienView) -> void:
	var increment: int = int(question.get("increment", 1))
	var axe: String = String(question.get("axe_manquant", "x"))
	var position: int = int(question.get("position", 0))
	_reponse_attendue = int(question.get("reponse", (position + 1) * increment))

	var etiquettes_completes := []
	for i in range(1, taille + 1):
		etiquettes_completes.append(str(i * increment))
	var etiquettes_vides := []
	etiquettes_vides.resize(taille)

	if axe == "x":
		vue.configurer(taille, etiquettes_vides, etiquettes_completes, position, -1)
	else:
		vue.configurer(taille, etiquettes_completes, etiquettes_vides, -1, position)

	var champ_reponse: LineEdit = %ChampReponse
	var bouton_valider: Button = %BoutonValider
	champ_reponse.text = ""
	champ_reponse.editable = true
	bouton_valider.disabled = false

func _configurer_lire_coordonnees(question: Dictionary, taille: int, vue: PlanCartesienView, zone_creature: Control) -> void:
	_x_attendu = int(question.get("x", 0))
	_y_attendu = int(question.get("y", 0))

	var etiquettes_x := []
	var etiquettes_y := []
	for i in range(1, taille + 1):
		etiquettes_x.append(str(i))
		etiquettes_y.append(str(i))
	vue.configurer(taille, etiquettes_x, etiquettes_y, -1, -1)

	var id_creature: int = int(question.get("id_creature", 1))
	_placer_creature(vue, zone_creature, "c%d" % id_creature)

	var champ_x: LineEdit = %ChampX
	var champ_y: LineEdit = %ChampY
	var bouton_valider: Button = %BoutonValiderCoords
	champ_x.text = ""
	champ_y.text = ""
	champ_x.editable = true
	champ_y.editable = true
	bouton_valider.disabled = false

func _placer_creature(vue: PlanCartesienView, zone_creature: Control, sprite_id: String) -> void:
	var texture_sprite: TextureRectAnime = %TextureSprite
	var placeholder: ColorRect = %PlaceholderSprite
	var texture := SpriteUtil.charger_texture(sprite_id)
	if texture != null:
		texture_sprite.configurer_animation(texture, SpriteUtil.compter_frames(texture))
		texture_sprite.visible = true
		placeholder.visible = false
	else:
		texture_sprite.visible = false
		placeholder.visible = true

	zone_creature.visible = true
	_vue_ref = vue
	_zone_creature_ref = zone_creature
	if not vue.resized.is_connected(_repositionner_creature):
		vue.resized.connect(_repositionner_creature)
	_repositionner_creature()

## L'ecran de tableau ajoute le widget a l'arbre AVANT de connaitre les
## dimensions finales apres layout (containers) : on recalcule donc la
## position de la creature a chaque redimensionnement du plan, plutot
## qu'une seule fois au moment de _placer_creature().
func _repositionner_creature() -> void:
	if _vue_ref == null or _zone_creature_ref == null or not _zone_creature_ref.visible:
		return
	var pixel := _vue_ref.point_vers_pixel(_x_attendu, _y_attendu)
	_zone_creature_ref.position = pixel - _zone_creature_ref.size / 2.0

func _connecter() -> void:
	if _connecte:
		return
	var champ_reponse: LineEdit = %ChampReponse
	var bouton_valider: Button = %BoutonValider
	bouton_valider.pressed.connect(_valider)
	champ_reponse.text_submitted.connect(func(_t): _valider())

	var champ_x: LineEdit = %ChampX
	var champ_y: LineEdit = %ChampY
	var bouton_valider_coords: Button = %BoutonValiderCoords
	bouton_valider_coords.pressed.connect(_valider_coordonnees)
	champ_x.text_submitted.connect(func(_t): _valider_coordonnees())
	champ_y.text_submitted.connect(func(_t): _valider_coordonnees())
	_connecte = true

func _valider() -> void:
	var champ_reponse: LineEdit = %ChampReponse
	if not champ_reponse.text.is_valid_int():
		return
	var valeur := int(champ_reponse.text)
	champ_reponse.editable = false
	var bouton_valider: Button = %BoutonValider
	bouton_valider.disabled = true
	reponse_donnee.emit(valeur == _reponse_attendue)

func _valider_coordonnees() -> void:
	var champ_x: LineEdit = %ChampX
	var champ_y: LineEdit = %ChampY
	if not champ_x.text.is_valid_int() or not champ_y.text.is_valid_int():
		return
	var valeur_x := int(champ_x.text)
	var valeur_y := int(champ_y.text)
	champ_x.editable = false
	champ_y.editable = false
	var bouton_valider: Button = %BoutonValiderCoords
	bouton_valider.disabled = true
	reponse_donnee.emit(valeur_x == _x_attendu and valeur_y == _y_attendu)
