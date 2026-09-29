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
## - "placer_point" (tableaux 4-5) : la consigne donne directement les
##   coordonnees d'une ou plusieurs creatures (question["creatures"],
##   un tableau - 1 entree au tableau 4, 2 au tableau 5) et l'enfant les
##   DEPLACE une a une (glisser-depose OU clic pour SELECTIONNER une
##   creature puis clic sur l'intersection voulue, boutons ronds
##   generes a chaque croisement de lignes - jamais au centre d'une
##   case, qui ne correspond a aucune coordonnee reelle sur un plan
##   cartesien) puis clique "Confirmer" une fois TOUTES placees.
## D'autres types seront ajoutes ici au fur et a mesure des prochains
## tableaux.
##
## Le cote "cible" du glisser-depose (_can_drop_data()/_drop_data())
## vit sur %ZonePlacement (ZoneDepotPlanCartesien, zone LOCALISEE au
## plan) et relaie un signal a ce script, plutot que d'implementer ces
## methodes ici : la racine de ce widget couvre TOUT L'ECRAN (comme
## chaque widget de tableau), et y activer la reception de glisser-
## depose a deja fait regresser le bouton Quitter/DEV du tableau (bug
## documente dans CLAUDE.md sur zone_reponse - une zone plein ecran qui
## "voit" les clics, meme sur ses parties vides, avale tout ce qui est
## dessous). voir creature_deplacable.gd pour le cote "source".
##
## Resout %Nom a la demande (voir widget_pair_impair.gd pour le
## pourquoi).

signal reponse_donnee(correcte: bool)

const CREATURE_SCENE := preload("res://scenes/components/CreatureDeplacable.tscn")
const TAILLE_CREATURE := Vector2(48, 48)
const SEPARATION_DEPART := 12.0

var _type: String = "completer_axe"
var _reponse_attendue: int = 0
var _x_attendu: int = 0
var _y_attendu: int = 0
var _connecte: bool = false

var _vue_ref: PlanCartesienView
var _zone_creature_ref: Control
var _zone_depart_ref: Control
var _boutons_intersections: Array = []

## Tableau "placer_point" : une entree par creature a placer, chacune
## {"x":int,"y":int,"node":CreatureDeplacable,"px":int,"py":int} - px/py
## = coordonnee candidate actuelle, -1 tant que jamais placee.
var _cibles_placement: Array = []
var _index_selectionne: int = 0

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter()
	_type = String(question.get("type", "completer_axe"))
	var taille: int = int(question.get("taille_grille", 5))

	var vue: PlanCartesienView = %Vue
	var zone_placement: ZoneDepotPlanCartesien = %ZonePlacement
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
	_effacer_creatures_placement()

	zone_creature.visible = false
	zone_depart.visible = false
	zone_saisie_axe.visible = false
	zone_saisie_coords.visible = false
	zone_saisie_placement.visible = false
	zone_placement.actif = (_type == "placer_point")

	match _type:
		"lire_coordonnees":
			zone_placement.custom_minimum_size = Vector2(380, 380)
			zone_saisie_coords.visible = true
			_configurer_lire_coordonnees(question, taille, vue, zone_creature)
			label_consigne.text = "Ecris les coordonnees (X, Y) de la creature."
		"placer_point":
			zone_depart.visible = true
			zone_saisie_placement.visible = true
			_configurer_placer_point(question, taille, vue, zone_placement, zone_depart)
			label_consigne.text = _consigne_placer_point()
		_:
			zone_placement.custom_minimum_size = Vector2(380, 380)
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

## --- Tableau "placer_point" : une ou plusieurs creatures, deplacees par clic ou glisser-depose ---

func _configurer_placer_point(question: Dictionary, taille: int, vue: PlanCartesienView, zone_placement: Control, zone_depart: Control) -> void:
	var creatures_data: Array = question.get("creatures", [])
	_index_selectionne = 0

	var etiquettes := []
	for i in range(1, taille + 1):
		etiquettes.append(str(i))
	vue.configurer(taille, etiquettes.duplicate(), etiquettes.duplicate(), -1, -1)

	var largeur_depart: float = maxf(90.0, creatures_data.size() * (TAILLE_CREATURE.x + SEPARATION_DEPART) + SEPARATION_DEPART)
	zone_depart.custom_minimum_size = Vector2(largeur_depart, 90)
	zone_placement.custom_minimum_size = Vector2(largeur_depart + 16.0 + 380.0, 380.0)

	for i in range(creatures_data.size()):
		var d: Dictionary = creatures_data[i]
		var noeud: CreatureDeplacable = CREATURE_SCENE.instantiate()
		noeud.index = i
		zone_placement.add_child(noeud)
		noeud.configurer("c%d" % int(d.get("id_creature", 1)))
		noeud.selectionnee.connect(_on_creature_selectionnee.bind(i))
		_cibles_placement.append({"x": int(d.get("x", 0)), "y": int(d.get("y", 0)), "node": noeud, "px": -1, "py": -1})

	_creer_boutons_intersections(taille, vue)
	_repositionner_creatures_au_depart()
	_mettre_a_jour_selection()
	_mettre_a_jour_bouton_confirmer()

func _consigne_placer_point() -> String:
	var parties := []
	for i in range(_cibles_placement.size()):
		var cible: Dictionary = _cibles_placement[i]
		parties.append("creature %d en (%d, %d)" % [i + 1, cible["x"], cible["y"]])
	var texte_cibles: String = ", ".join(parties)
	if _cibles_placement.size() > 1:
		return "Place chaque creature au bon endroit : %s. Clique une creature pour la choisir, puis glisse-la ou clique le bon croisement. Confirme quand toutes sont placees." % texte_cibles
	return "Place la creature en (%d, %d) : glisse-la ou clique le bon croisement, puis confirme." % [_cibles_placement[0]["x"], _cibles_placement[0]["y"]]

func _effacer_creatures_placement() -> void:
	for cible in _cibles_placement:
		var noeud = cible.get("node")
		if noeud != null and is_instance_valid(noeud):
			noeud.queue_free()
	_cibles_placement.clear()

func _repositionner_creatures_au_depart() -> void:
	if _zone_depart_ref == null:
		return
	var n := _cibles_placement.size()
	for i in range(n):
		var cible: Dictionary = _cibles_placement[i]
		if cible["px"] != -1:
			continue
		var noeud: CreatureDeplacable = cible["node"]
		var decalage_x := (i - (n - 1) / 2.0) * (TAILLE_CREATURE.x + SEPARATION_DEPART)
		noeud.position = _zone_depart_ref.position + _zone_depart_ref.size / 2.0 - noeud.size / 2.0 + Vector2(decalage_x, 0.0)

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
	_placer_creature_a(_index_selectionne, gx, gy)

func _on_creature_selectionnee(index: int) -> void:
	_index_selectionne = index
	_mettre_a_jour_selection()

## Met en evidence (agrandissement leger) la creature actuellement
## selectionnee - utile des qu'il y a plusieurs creatures, pour que
## l'enfant sache laquelle un clic d'intersection va deplacer.
func _mettre_a_jour_selection() -> void:
	for i in range(_cibles_placement.size()):
		var noeud: CreatureDeplacable = _cibles_placement[i]["node"]
		noeud.pivot_offset = noeud.size / 2.0
		noeud.scale = Vector2(1.2, 1.2) if i == _index_selectionne else Vector2.ONE

func _placer_creature_a(index: int, gx: int, gy: int) -> void:
	if index < 0 or index >= _cibles_placement.size():
		return
	_index_selectionne = index
	var cible: Dictionary = _cibles_placement[index]
	cible["px"] = gx
	cible["py"] = gy
	_cibles_placement[index] = cible
	if _vue_ref != null:
		var noeud: CreatureDeplacable = cible["node"]
		noeud.position = _vue_ref.position + _vue_ref.point_vers_pixel(gx, gy) - noeud.size / 2.0
	_mettre_a_jour_selection()
	_mettre_a_jour_bouton_confirmer()

## Le bouton "Confirmer" ne s'active qu'une fois TOUTES les creatures
## placees au moins une fois (pas forcement au bon endroit) - evite de
## pouvoir valider avant meme d'avoir essaye de placer chacune.
func _mettre_a_jour_bouton_confirmer() -> void:
	var toutes_placees := true
	for cible in _cibles_placement:
		if cible["px"] == -1:
			toutes_placees = false
			break
	var bouton_confirmer: Button = %BoutonConfirmer
	bouton_confirmer.disabled = not toutes_placees

## Repositionne tout ce qui depend des dimensions reelles du plan
## (creature de "lire_coordonnees", creatures/boutons d'intersection de
## "placer_point") : le widget est configure avant que le layout final
## des containers (ZonePlacement/FilaPlacement) soit connu, donc les
## positions calculees a la configuration peuvent etre perimees tant
## que le premier passage de layout reel n'a pas eu lieu.
func _repositionner_apres_layout() -> void:
	if _vue_ref == null:
		return
	match _type:
		"placer_point":
			for i in range(_cibles_placement.size()):
				var cible: Dictionary = _cibles_placement[i]
				if cible["px"] != -1:
					_placer_creature_a(i, cible["px"], cible["py"])
			_repositionner_creatures_au_depart()
			_repositionner_boutons_intersections()
		"lire_coordonnees":
			if _zone_creature_ref != null and _zone_creature_ref.visible:
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

## Appele par ZoneDepotPlanCartesien (%ZonePlacement) quand une creature
## y est deposee - voir zone_depot_plan_cartesien.gd pour pourquoi la
## detection de depot vit sur ce noeud LOCALISE plutot que sur la
## racine du widget (qui couvre tout l'ecran).
func _on_creature_deposee(index: int) -> void:
	if _vue_ref == null:
		return
	var point := _vue_ref.pixel_vers_point(_vue_ref.get_local_mouse_position())
	_placer_creature_a(index, point.x, point.y)

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

	var zone_placement: ZoneDepotPlanCartesien = %ZonePlacement
	zone_placement.creature_deposee.connect(_on_creature_deposee)

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
	var bouton_confirmer: Button = %BoutonConfirmer
	if bouton_confirmer.disabled:
		return
	bouton_confirmer.disabled = true
	var toutes_correctes := true
	for cible in _cibles_placement:
		if cible["px"] != cible["x"] or cible["py"] != cible["y"]:
			toutes_correctes = false
			break
	reponse_donnee.emit(toutes_correctes)
