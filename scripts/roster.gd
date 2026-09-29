extends Control
## Ecran Roster (section 7 de la spec + mecaniques "feel good" validees
## par Mike) : liste des creatures capturees, selection -> stats/stade/
## XP/affection, surnom personnalisable, evolution par attribution d'XP,
## systeme de berries (glisser-deposer depuis l'inventaire pour faire
## monter l'affection jusqu'au deblocage du sprite "glow"), et choix de
## la "creature principale" (bouton "Accompagne-moi !") qui accompagne
## le joueur dans les scenes de tableau (voir ecran_tableau.gd).

const CarteCreatureRosterScene := preload("res://scenes/components/CarteCreatureRoster.tscn")
const BerryItemScene := preload("res://scenes/components/BerryItem.tscn")

const DUREE_PULSE := 0.18
const DUREE_STRETCH := 0.45
const DUREE_HALO_MONTEE := 0.15
const DUREE_HALO_DESCENTE := 0.7

## Attribution d'XP par petits bonds (Phase 8, demande de Mike) : chaque
## clic sur "Attribuer XP" ajoute ce montant vers le PROCHAIN palier de
## la creature selectionnee (SaveManager.ajouter_xp_creature()), au lieu
## de deduire le cout complet d'un coup.
const INCREMENT_XP_MANUEL := 10

@onready var label_xp: Label = %LabelXp
@onready var bouton_retour: Button = %BoutonRetour
@onready var grille_creatures: GridContainer = %GrilleCreatures

@onready var zone_sprite: ZoneDropCreature = %ZoneSprite
@onready var halo: TextureRect = %Halo
@onready var texture_detail: TextureRectAnime = %TextureDetail
@onready var placeholder_detail: ColorRect = %PlaceholderDetail
@onready var label_placeholder_detail: Label = %LabelPlaceholderDetail
@onready var line_edit_surnom: LineEdit = %LineEditSurnom
@onready var label_stade_detail: Label = %LabelStadeDetail
@onready var barre_xp: ProgressBar = %BarreXp
@onready var label_barre_xp_texte: Label = %LabelBarreXpTexte
@onready var barre_affection: ProgressBar = %BarreAffection
@onready var label_barre_affection_texte: Label = %LabelBarreAffectionTexte
@onready var bouton_attribuer_xp: Button = %BoutonAttribuerXp
@onready var bouton_principale: Button = %BoutonPrincipale
@onready var label_statut: Label = %LabelStatut
@onready var particules_xp: CPUParticles2D = %ParticulesXp

@onready var liste_berries: HBoxContainer = %ListeBerries

var _cartes_par_id: Dictionary = {}
var _creature_selectionnee_id: String = ""

func _ready() -> void:
	bouton_retour.pressed.connect(func(): SceneTransition.changer_scene("res://scenes/Hub.tscn"))
	bouton_attribuer_xp.pressed.connect(_on_attribuer_xp_presse)
	bouton_principale.pressed.connect(_on_definir_principale_presse)
	line_edit_surnom.text_submitted.connect(func(_texte): _sauvegarder_surnom())
	line_edit_surnom.focus_exited.connect(_sauvegarder_surnom)
	zone_sprite.berry_deposee.connect(_on_berry_deposee)

	zone_sprite.pivot_offset = zone_sprite.size / 2.0
	particules_xp.position = zone_sprite.size / 2.0
	zone_sprite.resized.connect(func():
		zone_sprite.pivot_offset = zone_sprite.size / 2.0
		particules_xp.position = zone_sprite.size / 2.0
	)

	_actualiser_label_xp()
	_peupler_liste()
	_peupler_berries()

func _actualiser_label_xp() -> void:
	label_xp.text = "XP : %d" % SaveManager.get_xp_total()

## --- Liste des creatures capturees ---

func _peupler_liste() -> void:
	var capturees: Dictionary = SaveManager.get_creatures_capturees()
	var premier_id := ""
	for creature_id in capturees.keys():
		if not DataManager.creatures.has(creature_id):
			continue
		if premier_id.is_empty():
			premier_id = creature_id
		var carte := CarteCreatureRosterScene.instantiate()
		grille_creatures.add_child(carte)
		_configurer_carte_liste(carte, creature_id)
		carte.selectionnee.connect(_selectionner_creature)
		_cartes_par_id[creature_id] = carte

	_actualiser_badges_principale()

	if not premier_id.is_empty():
		_selectionner_creature(premier_id)
	else:
		label_statut.text = "Aucune creature capturee."
		bouton_attribuer_xp.disabled = true
		bouton_principale.disabled = true

## Met a jour le badge "★" sur la carte de la creature principale
## actuelle (et l'enleve de toutes les autres).
func _actualiser_badges_principale() -> void:
	var principale_id := SaveManager.get_creature_principale_id()
	for creature_id in _cartes_par_id.keys():
		_cartes_par_id[creature_id].definir_principale(creature_id == principale_id)

func _configurer_carte_liste(carte, creature_id: String) -> void:
	var stage := SaveManager.get_stage_creature(creature_id)
	carte.configurer(creature_id, DataManager.creatures[creature_id], stage)
	var surnom := SaveManager.get_surnom_creature(creature_id)
	if not surnom.is_empty():
		carte.get_node("%LabelNom").text = surnom

func _selectionner_creature(creature_id: String) -> void:
	if _cartes_par_id.has(_creature_selectionnee_id):
		_cartes_par_id[_creature_selectionnee_id].definir_selectionnee(false)

	_creature_selectionnee_id = creature_id
	if _cartes_par_id.has(creature_id):
		_cartes_par_id[creature_id].definir_selectionnee(true)

	_actualiser_details()

## --- Panneau de details ---

func _actualiser_details() -> void:
	var creature_data: Dictionary = DataManager.creatures.get(_creature_selectionnee_id, {})
	var stage_actuel := SaveManager.get_stage_creature(_creature_selectionnee_id)
	var stage_max: int = int(creature_data.get("stages", 1))
	var forms: Dictionary = creature_data.get("forms", {})
	var names: Dictionary = creature_data.get("names", {})
	var sprite_id: String = String(forms.get("stage%d" % stage_actuel, ""))
	var est_glow := SaveManager.est_glow_creature(_creature_selectionnee_id)

	var texture := SpriteUtil.charger_texture_avec_glow(sprite_id, est_glow)
	if texture != null:
		texture_detail.configurer_animation(texture, SpriteUtil.compter_frames(texture))
		texture_detail.visible = true
		placeholder_detail.visible = false
	else:
		texture_detail.visible = false
		placeholder_detail.visible = true
		var texte_placeholder: String = sprite_id if not sprite_id.is_empty() else "?"
		if SpriteUtil.glow_manquant(sprite_id, est_glow):
			texte_placeholder += "\n(glow)"
			placeholder_detail.color = Color(1.0, 0.92, 0.55, 1.0)
		else:
			placeholder_detail.color = Color(0.45, 0.47, 0.55, 1.0)
		label_placeholder_detail.text = texte_placeholder

	var nom_espece: String = String(names.get("stage%d" % stage_actuel, _creature_selectionnee_id))
	line_edit_surnom.placeholder_text = nom_espece
	line_edit_surnom.text = SaveManager.get_surnom_creature(_creature_selectionnee_id)

	label_stade_detail.text = "Stade %d / %d" % [stage_actuel, stage_max]

	_actualiser_barre_xp(stage_actuel, stage_max)
	_actualiser_barre_affection()
	_actualiser_bouton_attribuer(stage_actuel, stage_max)
	_actualiser_bouton_principale()

func _actualiser_bouton_principale() -> void:
	if _creature_selectionnee_id == SaveManager.get_creature_principale_id():
		bouton_principale.disabled = true
		bouton_principale.text = "Creature principale actuelle"
	else:
		bouton_principale.disabled = false
		bouton_principale.text = "Accompagne-moi !"

## Barre de PROGRESSION VERS LE PROCHAIN PALIER de cette creature
## specifiquement (SaveManager.get_progression_stade_creature()) — PAS
## le total XP du portefeuille du joueur. Bug corrige : avant, la barre
## affichait min(xp_total_du_joueur, cout), donc le MEME nombre (ex.
## 200 XP) apparaissait sur la barre de toutes les creatures, laissant
## croire a tort qu'elles progressaient toutes pareil.
func _actualiser_barre_xp(stage_actuel: int, stage_max: int) -> void:
	if stage_actuel >= stage_max:
		barre_xp.max_value = 1
		barre_xp.value = 1
		label_barre_xp_texte.text = "Stade maximal"
		return
	var cout: int = SaveManager.cout_evolution_vers(stage_actuel + 1)
	var progression: int = SaveManager.get_progression_stade_creature(_creature_selectionnee_id)
	barre_xp.max_value = cout
	barre_xp.value = progression
	label_barre_xp_texte.text = "%d / %d XP" % [progression, cout]

func _actualiser_barre_affection() -> void:
	var affection := SaveManager.get_affection_creature(_creature_selectionnee_id)
	var affection_plafonnee: int = min(affection, SaveManager.SEUIL_GLOW)
	barre_affection.value = affection_plafonnee
	if affection >= SaveManager.SEUIL_GLOW:
		label_barre_affection_texte.text = "♥ Complice ! (glow debloque)"
	else:
		label_barre_affection_texte.text = "♥ %d / %d" % [affection, SaveManager.SEUIL_GLOW]

func _actualiser_bouton_attribuer(stage_actuel: int, stage_max: int) -> void:
	if stage_actuel >= stage_max:
		bouton_attribuer_xp.disabled = true
		bouton_attribuer_xp.text = "Stade maximal atteint"
		label_statut.text = ""
		return

	bouton_attribuer_xp.text = "Attribuer +%d XP" % INCREMENT_XP_MANUEL
	if SaveManager.get_xp_total() < INCREMENT_XP_MANUEL:
		bouton_attribuer_xp.disabled = true
		label_statut.text = "XP insuffisant (%d requis)" % INCREMENT_XP_MANUEL
	else:
		bouton_attribuer_xp.disabled = false
		label_statut.text = ""

func _sauvegarder_surnom() -> void:
	if _creature_selectionnee_id.is_empty():
		return
	SaveManager.definir_surnom_creature(_creature_selectionnee_id, line_edit_surnom.text)
	if _cartes_par_id.has(_creature_selectionnee_id):
		var nom_affiche := SaveManager.get_surnom_creature(_creature_selectionnee_id)
		if nom_affiche.is_empty():
			nom_affiche = line_edit_surnom.placeholder_text
		_cartes_par_id[_creature_selectionnee_id].get_node("%LabelNom").text = nom_affiche

func _on_definir_principale_presse() -> void:
	SaveManager.definir_creature_principale(_creature_selectionnee_id)
	label_statut.text = "Elle t'accompagnera dans les tableaux !"
	_actualiser_badges_principale()
	_actualiser_bouton_principale()

## --- Attribution d'XP par bonds de 10 (Phase 8, demande de Mike) :
## pulsation + particules a chaque clic, evolution automatique des que
## le palier de la creature SELECTIONNEE est atteint. ---

func _on_attribuer_xp_presse() -> void:
	var creature_data: Dictionary = DataManager.creatures.get(_creature_selectionnee_id, {})
	var stage_max: int = int(creature_data.get("stages", 1))
	var resultat := SaveManager.ajouter_xp_creature(_creature_selectionnee_id, INCREMENT_XP_MANUEL, stage_max)
	if not bool(resultat.get("applique", false)):
		label_statut.text = "Impossible d'attribuer de l'XP."
		return

	label_statut.text = "Evolution reussie !" if bool(resultat.get("evolue", false)) else "+%d XP attribues !" % INCREMENT_XP_MANUEL
	_jouer_effet_attribution_xp()
	_actualiser_label_xp()
	_actualiser_details()

	if _cartes_par_id.has(_creature_selectionnee_id):
		_configurer_carte_liste(_cartes_par_id[_creature_selectionnee_id], _creature_selectionnee_id)

func _jouer_effet_attribution_xp() -> void:
	particules_xp.restart()
	particules_xp.emitting = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(zone_sprite, "scale", Vector2(1.18, 1.18), DUREE_PULSE)
	tween.tween_property(zone_sprite, "scale", Vector2(1.0, 1.0), DUREE_PULSE)

## --- Berries : inventaire, glisser-deposer, effet stretch+glow ---

func _peupler_berries() -> void:
	for enfant in liste_berries.get_children():
		enfant.queue_free()
	var inventaire := SaveManager.get_berries_inventaire()
	for i in range(inventaire.size()):
		var item := BerryItemScene.instantiate()
		liste_berries.add_child(item)
		item.configurer(i, int(inventaire[i]))

func _on_berry_deposee(donnees: Dictionary) -> void:
	if _creature_selectionnee_id.is_empty():
		return
	var index_inventaire: int = int(donnees.get("index_inventaire", -1))
	if not SaveManager.consommer_berry(index_inventaire):
		return

	var nouvelle_affection := SaveManager.donner_berry_a_creature(_creature_selectionnee_id)
	_peupler_berries()
	_actualiser_barre_affection()
	_jouer_effet_berry(nouvelle_affection)

	if nouvelle_affection == SaveManager.SEUIL_GLOW:
		label_statut.text = "Sprite glow debloque !"
		_actualiser_details()
	elif _cartes_par_id.has(_creature_selectionnee_id):
		_configurer_carte_liste(_cartes_par_id[_creature_selectionnee_id], _creature_selectionnee_id)

func _jouer_effet_berry(_nouvelle_affection: int) -> void:
	# Stretch elastique.
	var tween_stretch := create_tween()
	tween_stretch.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween_stretch.tween_property(zone_sprite, "scale", Vector2(1.3, 0.75), 0.08)
	tween_stretch.tween_property(zone_sprite, "scale", Vector2(1.0, 1.0), DUREE_STRETCH)

	# Halo blanc/rose qui monte vite puis redescend doucement.
	if halo.material is ShaderMaterial:
		var tween_halo := create_tween()
		tween_halo.tween_property(halo.material, "shader_parameter/intensite", 1.0, DUREE_HALO_MONTEE)
		tween_halo.tween_property(halo.material, "shader_parameter/intensite", 0.0, DUREE_HALO_DESCENTE)
