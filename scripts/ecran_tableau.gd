extends Control
## Ecran de tableau reel (section 9 de la spec), remplace
## EcranTableauPlaceholder.tscn. Pose les 10 questions scriptees du
## niveau courant (GameState.matiere_courante_id / niveau_courant_id),
## en delegant l'affichage/la saisie de chaque question a un "widget de
## reponse" reutilisable (scripts/tableau/, un par matiere) qui respecte
## un contrat commun :
##   func configurer(question: Dictionary, contexte: Dictionary) -> void
##   signal reponse_donnee(correcte: bool)
## Cette classe gere tout ce qui est commun aux 8 matieres : progression
## dans les questions, score, XP (+10/bonne reponse, +50 bonus si >=8/10),
## distribution de berries (+1/bonne reponse, skin aleatoire), et l'ecran
## de resultats + deblocage du niveau suivant en fin de tableau.
##
## Cote joueur, la creature affichee est la "creature principale" choisie
## depuis le Roster (bouton "Accompagne-moi !",
## SaveManager.get_creature_principale_id()) — elle reste la meme tant
## que le joueur n'en choisit pas une autre. Repli si aucun choix
## explicite n'a encore ete fait : le starter, sinon la premiere
## creature capturee (voir SaveManager.get_creature_principale_id()).
##
## Cote sauvage (section 9.1 de la spec, Phase 7) : une creature
## non-evoluee est tiree au hasard parmi celles jamais encore vues
## (RencontreUtil.tirer_creature_sauvage()), UNE SEULE FOIS par tableau
## (SaveManager.get/definir_creature_rencontre() memorise l'association
## matiere+niveau -> creature, pour qu'un tableau rejoue toujours la
## meme creature). Vue des l'entree dans le tableau (reussi ou non) ;
## capturee seulement si le tableau est reussi (>=7/10).

const NB_NIVEAUX := 10
const SEUIL_REUSSITE := 7
const SEUIL_BONUS := 8
const BONUS_XP := 50
const XP_PAR_BONNE_REPONSE := 10
const DUREE_FEEDBACK := 1.1

const WidgetPairImpair := preload("res://scenes/tableau/WidgetPairImpair.tscn")
const WidgetApproximation := preload("res://scenes/tableau/WidgetApproximation.tscn")
const WidgetTermeManquant := preload("res://scenes/tableau/WidgetTermeManquant.tscn")
const WidgetPlanCartesien := preload("res://scenes/tableau/WidgetPlanCartesien.tscn")
const WidgetPossibleImpossible := preload("res://scenes/tableau/WidgetPossibleImpossible.tscn")
const WidgetTableauPictogramme := preload("res://scenes/tableau/WidgetTableauPictogramme.tscn")
const WidgetFractions := preload("res://scenes/tableau/WidgetFractions.tscn")
const WidgetCroissantDecroissant := preload("res://scenes/tableau/WidgetCroissantDecroissant.tscn")

@onready var label_xp: Label = %LabelXp
@onready var bouton_quitter: Button = %BoutonQuitter
@onready var label_titre: Label = %LabelTitre
@onready var label_question: Label = %LabelQuestion
@onready var label_feedback: Label = %LabelFeedback
@onready var zone_reponse: Control = %ZoneReponse
@onready var texture_joueur: TextureRect = %TextureJoueur
@onready var placeholder_joueur: ColorRect = %PlaceholderJoueur
@onready var label_nom_joueur: Label = %LabelNomJoueur
@onready var texture_sauvage: TextureRect = %TextureSauvage
@onready var placeholder_sauvage: ColorRect = %PlaceholderSauvage
@onready var label_sauvage: Label = %LabelSauvage
@onready var label_nom_sauvage: Label = %LabelNomSauvage
@onready var timer_avance: Timer = %TimerAvance

@onready var panneau_resultats: PanelContainer = %PanneauResultats
@onready var label_resultats_titre: Label = %LabelResultatsTitre
@onready var label_resultats_details: Label = %LabelResultatsDetails
@onready var bouton_continuer: Button = %BoutonContinuer

var _matiere_id: String = ""
var _niveau_id: String = ""
var _questions: Array = []
var _contexte: Dictionary = {}
var _index_question: int = 0
var _score: int = 0
var _berries_gagnees: int = 0
var _xp_gagne: int = 0
var _widget_courant: Control = null
var _creature_sauvage_id: String = ""

func _ready() -> void:
	bouton_quitter.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/SelectionNiveau.tscn"))
	bouton_continuer.pressed.connect(_on_continuer_presse)
	timer_avance.one_shot = true
	timer_avance.wait_time = DUREE_FEEDBACK
	timer_avance.timeout.connect(_question_suivante)

	_matiere_id = GameState.matiere_courante_id
	_niveau_id = GameState.niveau_courant_id

	var niveau_data := DataManager.load_niveau("%s_%s" % [_matiere_id, _niveau_id])
	_questions = niveau_data.get("questions", [])
	_contexte = {"graphique": niveau_data.get("graphique", {})}

	var matiere := DataManager.get_matiere_by_id(_matiere_id)
	label_titre.text = "%s - %s" % [String(matiere.get("nom", _matiere_id)), String(niveau_data.get("nom", _niveau_id))]

	_actualiser_label_xp()
	_afficher_creature_joueur()
	_preparer_rencontre()
	_instancier_widget()
	_afficher_question(0)

func _actualiser_label_xp() -> void:
	label_xp.text = "XP : %d" % SaveManager.get_xp_total()

func _afficher_creature_joueur() -> void:
	var creature_id: String = SaveManager.get_creature_principale_id()
	if creature_id.is_empty() or not DataManager.creatures.has(creature_id):
		return
	var creature_data: Dictionary = DataManager.creatures[creature_id]
	var stage := SaveManager.get_stage_creature(creature_id)
	var forms: Dictionary = creature_data.get("forms", {})
	var names: Dictionary = creature_data.get("names", {})
	var sprite_id: String = String(forms.get("stage%d" % stage, ""))
	var est_glow := SaveManager.est_glow_creature(creature_id)

	var texture := SpriteUtil.charger_texture_avec_glow(sprite_id, est_glow)
	if texture != null:
		texture_joueur.texture = texture
		texture_joueur.visible = true
		placeholder_joueur.visible = false

	var surnom := SaveManager.get_surnom_creature(creature_id)
	if not surnom.is_empty():
		label_nom_joueur.text = surnom
	else:
		label_nom_joueur.text = String(names.get("stage%d" % stage, creature_id))

## Tire (ou retrouve) la creature sauvage de CE tableau precis, l'affiche
## et la marque comme vue. Voir le commentaire d'entete pour le detail.
func _preparer_rencontre() -> void:
	var tableau_id := "%s_%s" % [_matiere_id, _niveau_id]
	_creature_sauvage_id = SaveManager.get_creature_rencontre(tableau_id)
	if _creature_sauvage_id.is_empty():
		_creature_sauvage_id = RencontreUtil.tirer_creature_sauvage(
			DataManager.get_creatures_non_evoluees(),
			SaveManager.get_creatures_vues()
		)
		if not _creature_sauvage_id.is_empty():
			SaveManager.definir_creature_rencontre(tableau_id, _creature_sauvage_id)

	if _creature_sauvage_id.is_empty():
		return
	SaveManager.marquer_vue(_creature_sauvage_id)
	_afficher_creature_sauvage()

func _afficher_creature_sauvage() -> void:
	if not DataManager.creatures.has(_creature_sauvage_id):
		return
	var creature_data: Dictionary = DataManager.creatures[_creature_sauvage_id]
	var forms: Dictionary = creature_data.get("forms", {})
	var names: Dictionary = creature_data.get("names", {})
	# Une creature sauvage rencontree en tableau est toujours non-evoluee (stage1).
	var sprite_id: String = String(forms.get("stage1", ""))

	var texture := SpriteUtil.charger_texture(sprite_id)
	if texture != null:
		texture_sauvage.texture = texture
		texture_sauvage.visible = true
		placeholder_sauvage.visible = false
	else:
		texture_sauvage.visible = false
		placeholder_sauvage.visible = true
		label_sauvage.text = sprite_id if not sprite_id.is_empty() else "?"

	label_nom_sauvage.text = String(names.get("stage1", _creature_sauvage_id))

func _instancier_widget() -> void:
	var scenes := {
		"pair_impair": WidgetPairImpair,
		"approximation": WidgetApproximation,
		"terme_manquant": WidgetTermeManquant,
		"plan_cartesien": WidgetPlanCartesien,
		"possible_impossible": WidgetPossibleImpossible,
		"tableau_pictogramme": WidgetTableauPictogramme,
		"fractions": WidgetFractions,
		"croissant_decroissant": WidgetCroissantDecroissant,
	}
	var scene: PackedScene = scenes.get(_matiere_id)
	if scene == null:
		return
	_widget_courant = scene.instantiate()
	zone_reponse.add_child(_widget_courant)
	_widget_courant.reponse_donnee.connect(_on_reponse_donnee)

func _afficher_question(index: int) -> void:
	if index >= _questions.size():
		_terminer_tableau()
		return
	_index_question = index
	label_question.text = "Question %d / %d" % [index + 1, _questions.size()]
	label_feedback.text = ""
	_widget_courant.configurer(_questions[index], _contexte)

func _on_reponse_donnee(correcte: bool) -> void:
	if correcte:
		_score += 1
		SaveManager.add_xp(XP_PAR_BONNE_REPONSE)
		SaveManager.ajouter_berry()
		_berries_gagnees += 1
		_xp_gagne += XP_PAR_BONNE_REPONSE
		label_feedback.text = "Bonne reponse ! +%d XP, +1 berry" % XP_PAR_BONNE_REPONSE
		label_feedback.modulate = Color(0.4, 0.9, 0.5, 1)
	else:
		label_feedback.text = "Pas tout a fait..."
		label_feedback.modulate = Color(0.95, 0.5, 0.4, 1)
	_actualiser_label_xp()
	timer_avance.start()

func _question_suivante() -> void:
	_afficher_question(_index_question + 1)

func _terminer_tableau() -> void:
	var reussi: bool = _score >= SEUIL_REUSSITE
	var bonus := 0
	if _score >= SEUIL_BONUS:
		bonus = BONUS_XP
		SaveManager.add_xp(BONUS_XP)
		_xp_gagne += BONUS_XP

	SaveManager.set_progression_niveau(_matiere_id, _niveau_id, reussi, _score, true)
	if reussi:
		var numero_actuel: int = int(_niveau_id.replace("niveau_", ""))
		if numero_actuel < NB_NIVEAUX:
			var niveau_suivant_id := "niveau_%02d" % (numero_actuel + 1)
			SaveManager.set_progression_niveau(_matiere_id, niveau_suivant_id, false, 0, true)

	var creature_capturee: bool = false
	if reussi and not _creature_sauvage_id.is_empty():
		creature_capturee = not SaveManager.get_creatures_capturees().has(_creature_sauvage_id)
		SaveManager.capturer_creature(_creature_sauvage_id)

	_actualiser_label_xp()
	_afficher_resultats(reussi, bonus, creature_capturee)

func _afficher_resultats(reussi: bool, bonus: int, creature_capturee: bool) -> void:
	zone_reponse.visible = false
	panneau_resultats.visible = true

	label_resultats_titre.text = "Niveau reussi !" if reussi else "Pas encore reussi..."
	var lignes := []
	lignes.append("Score : %d / %d" % [_score, _questions.size()])
	lignes.append("Berries gagnees : %d" % _berries_gagnees)
	var texte_xp := "XP gagne : %d" % _xp_gagne
	if bonus > 0:
		texte_xp += " (dont %d de bonus)" % bonus
	lignes.append(texte_xp)
	if reussi:
		if creature_capturee:
			var nom_sauvage: String = label_nom_sauvage.text if not label_nom_sauvage.text.is_empty() else "La creature"
			lignes.append("%s a rejoint ton roster !" % nom_sauvage)
		lignes.append("Le niveau suivant est debloque !")
	else:
		lignes.append("Il faut au moins %d/10 pour reussir. Retente quand tu veux !" % SEUIL_REUSSITE)
	label_resultats_details.text = "\n".join(lignes)

func _on_continuer_presse() -> void:
	get_tree().change_scene_to_file("res://scenes/SelectionNiveau.tscn")
