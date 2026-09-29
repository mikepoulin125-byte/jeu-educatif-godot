extends Control
## Widget "plan_cartesien". Le plan est toujours dessine par le meme
## composant partage (PlanCartesienView - axes flesches + quadrillage,
## MEME visuel pour tous les tableaux du badge). Trois types de question
## geres via question["type"] :
## - "completer_axe" (tableaux 1-2) : un axe complet, l'autre vide sauf
##   une graduation en evidence (rond rouge) que l'enfant ecrit.
## - "lire_coordonnees" (tableau 3) : les deux axes sont complets, une
##   creature est placee a un point (x, y) et l'enfant ecrit les deux
##   coordonnees.
## - "placer_point" (tableau 4) : la consigne donne directement les
##   coordonnees (ex. "(4, 6)") et l'enfant DEPLACE la creature
##   (glisser-depose OU clic sur l'intersection voulue, boutons ronds
##   generes a chaque croisement de lignes - jamais au centre d'une
##   case, qui ne correspond a aucune coordonnee reelle sur un plan
##   cartesien) puis clique "Confirmer".
## D'autres types seront ajoutes ici au fur et a mesure des prochains
## tableaux.
##
## Gere lui-meme _can_drop_data()/_drop_data() (cote "cible" du
## glisser-depose de la creature, voir creature_deplacable.gd pour le
## cote "source") plutot que PlanCartesienView, qui reste un composant
## purement visuel/reutilisable.
##
## Resout %Nom a la demande (voir widget_pair_impair.gd pour le
## pourquoi).

signal reponse_donnee(correcte: bool)

var _type: String = "completer_axe"
var _reponse_attendue: int = 0
var _x_attendu: int = 0
var _y_attendu: int = 0
var _connecte: bool = false

var _vue_ref: PlanCartesienView
var _zone_creature_ref: Control
var _zone_depart_ref: Control
var _candidate_x: int = -1
var _candidate_y: int = -1
var _candidate_definie: bool = false
var _boutons_intersections: Array = []

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	_type = String(question.get("type", "completer_axe"))
	var taille: int = int(question.get("taille_grille", 5))

	var vue: PlanCartesienView = %Vue
	var zone_placement: Control = %ZonePlacement
	var zone_depart: Control = %ZoneDepart
	var zone_creature: Control = %ZoneCreature
	var zone_saisie_axe: Control = %ZoneSaisieAxe
	var zone_saisie_coords: Control = %ZoneSaisieCoords
	var zone_saisie_placement: Control = %ZoneSaisiePlacement
	var label_consigne: Label = %LabelConsigne

	_vue_ref = vue
	_zone_creature_ref = zone_creature
	_zone_depart_ref = zone_depart
	_effacer_boutons_intersections()

	zone_creature.visible = false
	zone_depart.visible = false
	zone_saisie_axe.visible = false
	zone_saisie_coords.visible = false
	zone_saisie_placement.visible = false
	zone_placement.custom_minimum_size = Vector2(486, 380) if _type == "placer_point" else Vector2(380, 380)

	match _type:
		"lire_coordonnees":
			zone_saisie_coords.visible = true
			_configurer_lire_coordonnees(question, taille, vue, zone_creature)
			label_consigne.text = "Ecris les coordonnees (X, Y) de la creature."
		"placer_point":
			zone_depart.visible = true
			zone_saisie_placement.visible = true
			_configurer_placer_point(question, taille, vue, zone_creature)
			label_consigne.text = "Place la creature en (%d, %d) : glisse-la ou clique le bon croisement, puis confirme." % [_x_attendu, _y_attendu]
		_:
			zone_saisie_axe.visible = true
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
	_charger_texture_creature("c%d" % id_creature)
	zone_creature.visible = true
	zone_creature.position = vue.position + vue.point_vers_pixel(_x_attendu, _y_attendu) - zone_creature.size / 2.0

	var champ_x: LineEdit = %ChampX
	var champ_y: LineEdit = %ChampY
	var bouton_valider: Button = %BoutonValiderCoords
	champ_x.text = ""
	champ_y.text = ""
	champ_x.editable = true
	champ_y.editable = true
	bouton_valider.disabled = false

func _configurer_placer_point(question: Dictionary, taille: int, vue: PlanCartesienView, zone_creature: Control) -> void:
	_x_attendu = int(question.get("x", 0))
	_y_attendu = int(question.get("y", 0))
	_candidate_x = -1
	_candidate_y = -1
	_candidate_definie = false

	var etiquettes := []
	for i in range(1, taille + 1):
		etiquettes.append(str(i))
	vue.configurer(taille, etiquettes.duplicate(), etiquettes.duplicate(), -1, -1)

	var id_creature: int = int(question.get("id_creature", 1))
	_charger_texture_creature("c%d" % id_creature)
	zone_creature.visible = true
	_replacer_creature_au_depart()
	_creer_boutons_intersections(taille, vue)

	var bouton_confirmer: Button = %BoutonConfirmer
	bouton_confirmer.disabled = true

func _charger_texture_creature(sprite_id: String) -> void:
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

## --- Tableau "placer_point" : deplacement (clic ou glisser-depose) ---

func _replacer_creature_au_depart() -> void:
	if _zone_depart_ref == null or _zone_creature_ref == null:
		return
	_zone_creature_ref.position = _zone_depart_ref.position + _zone_depart_ref.size / 2.0 - _zone_creature_ref.size / 2.0

func _creer_boutons_intersections(taille: int, vue: PlanCartesienView) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.9, 0.35)
	style.set_corner_radius_all(20)
	var style_survol := style.duplicate()
	style_survol.bg_color = Color(0.2, 0.4, 0.9, 0.6)
	for gy in range(taille + 1):
		for gx in range(taille + 1):
			var bouton := Button.new()
			bouton.custom_minimum_size = Vector2(22, 22)
			bouton.size = Vector2(22, 22)
			bouton.text = ""
			bouton.focus_mode = Control.FOCUS_NONE
			bouton.flat = true
			bouton.add_theme_stylebox_override("normal", style)
			bouton.add_theme_stylebox_override("hover", style_survol)
			bouton.add_theme_stylebox_override("pressed", style_survol)
			vue.add_child(bouton)
			bouton.position = vue.point_vers_pixel(gx, gy) - bouton.size / 2.0
			bouton.pressed.connect(_on_intersection_pressee.bind(gx, gy))
			_boutons_intersections.append(bouton)

func _effacer_boutons_intersections() -> void:
	for bouton in _boutons_intersections:
		if is_instance_valid(bouton):
			bouton.queue_free()
	_boutons_intersections.clear()

func _on_intersection_pressee(gx: int, gy: int) -> void:
	_placer_creature_a(gx, gy)

func _placer_creature_a(gx: int, gy: int) -> void:
	_candidate_x = gx
	_candidate_y = gy
	_candidate_definie = true
	if _vue_ref != null and _zone_creature_ref != null:
		_zone_creature_ref.position = _vue_ref.position + _vue_ref.point_vers_pixel(gx, gy) - _zone_creature_ref.size / 2.0
	var bouton_confirmer: Button = %BoutonConfirmer
	bouton_confirmer.disabled = false

## Repositionne tout ce qui depend des dimensions reelles du plan
## (creature de "lire_coordonnees"/"placer_point", boutons
## d'intersection) : le widget est configure avant que le layout final
## des containers (ZonePlacement/FilaPlacement) soit connu, donc les
## positions calculees a la configuration peuvent etre perimees tant
## que le premier passage de layout reel n'a pas eu lieu.
func _repositionner_apres_layout() -> void:
	if _vue_ref == null or _zone_creature_ref == null:
		return
	match _type:
		"placer_point":
			if _candidate_definie:
				_placer_creature_a(_candidate_x, _candidate_y)
			else:
				_replacer_creature_au_depart()
			_repositionner_boutons_intersections()
		"lire_coordonnees":
			if _zone_creature_ref.visible:
				_zone_creature_ref.position = _vue_ref.position + _vue_ref.point_vers_pixel(_x_attendu, _y_attendu) - _zone_creature_ref.size / 2.0

func _repositionner_boutons_intersections() -> void:
	var taille := _vue_ref.taille
	var i := 0
	for gy in range(taille + 1):
		for gx in range(taille + 1):
			if i >= _boutons_intersections.size():
				return
			var bouton: Button = _boutons_intersections[i]
			bouton.position = _vue_ref.point_vers_pixel(gx, gy) - bouton.size / 2.0
			i += 1

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return _type == "placer_point" and typeof(data) == TYPE_DICTIONARY and data.get("type") == "creature_plan_cartesien"

func _drop_data(_at_position: Vector2, _data) -> void:
	if _vue_ref == null:
		return
	var point := _vue_ref.pixel_vers_point(_vue_ref.get_local_mouse_position())
	_placer_creature_a(point.x, point.y)

## --- Connexions (une seule fois, voir widget_pair_impair.gd) ---

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

	var bouton_confirmer: Button = %BoutonConfirmer
	bouton_confirmer.pressed.connect(_valider_placement)

	var fila_placement: HBoxContainer = %FilaPlacement
	fila_placement.sort_children.connect(_repositionner_apres_layout)

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

func _valider_placement() -> void:
	if not _candidate_definie:
		return
	var bouton_confirmer: Button = %BoutonConfirmer
	bouton_confirmer.disabled = true
	reponse_donnee.emit(_candidate_x == _x_attendu and _candidate_y == _y_attendu)
