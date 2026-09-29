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
const RATIO_REUSSITE := 0.7
const RATIO_BONUS := 0.8
const BONUS_XP := 50
const XP_PAR_BONNE_REPONSE := 10
const DUREE_FEEDBACK := 1.1
const NIVEAU_ID_EXAMEN := "examen"

## Skin fixe (pas aleatoire) utilise pour IDENTIFIER visuellement les
## berries dans la barre de comptage — le skin reellement gagne (tirage
## aleatoire, SaveManager.ajouter_berry()) reste inchange, c'est juste
## l'icone d'affichage de la barre qui est fixe (demande de Mike).
const SKIN_BERRY_BARRE := 7

const DUREE_POP_BERRY := 0.15
const DUREE_PAUSE_BERRY := 0.15
const DUREE_VOL_BERRY := 0.45
const TAILLE_BERRY_VOLANTE := 40.0

## Duree entre chaque increment UNITAIRE du compteur d'XP (effet
## "machine a sous" : les chiffres defilent vite un par un, pas un
## lerp lisse — voir _animer_xp_gagne()).
const PAS_ANIM_XP := 0.045

## Animation d'impact (bonne reponse) : la creature du joueur "charge" la
## creature sauvage, impact, recul, flash blanc sur la sauvage. Doit tenir
## largement dans DUREE_FEEDBACK (1.1s) — tourne en parallele des anims
## XP/berry sur d'autres noeuds, aucun conflit.
const DUREE_LUNGE := 0.12
const DUREE_RECOIL := 0.22
const DISTANCE_LUNGE := 130.0
const DUREE_FLASH := 0.18

## Le son d'attaque joue IMMEDIATEMENT au clic sur la bonne reponse, mais
## l'anim (charge/impact/recul) ne demarre qu'apres ce delai (demande de
## Mike : 1 seconde apres le DEBUT du son, pas apres sa fin). timer_avance
## doit donc attendre au moins DELAI_AVANT_ATTAQUE + DUREE_LUNGE +
## DUREE_RECOIL avant de passer a la question suivante, sinon la question
## changerait pendant que l'anim joue encore (voir _on_reponse_donnee()).
const DELAI_AVANT_ATTAQUE := 1.0
const DUREE_FEEDBACK_AVEC_ATTAQUE := DELAI_AVANT_ATTAQUE + DUREE_LUNGE + DUREE_RECOIL + 0.15

## Sequence de capture (derniere reponse d'un tableau REUSSI, >=70%%,
## remplace l'anim d'impact) : catch.gif est lance depuis le coin
## gauche-bas de l'ecran vers la creature sauvage en une legere courbe
## (2 segments tween-es vers un point "sommet" plus haut, voir
## _jouer_sequence_capture()), joue une fois (clamp, voir
## TextureRectAnime.configurer_animation_unique()), puis vers les 3/4 de
## sa lecture la creature sauvage retrecit et est "aspiree" dans le gif
## avant de disparaitre.
const DUREE_LANCER_CATCH := 0.45
const HAUTEUR_ARC_LANCER_CATCH := 90.0
const DUREE_ABSORPTION_SAUVAGE := 0.35
const FRACTION_ABSORPTION_GIF := 0.75
const MARGE_DEPART_CATCH := 30.0

const WidgetPairImpair := preload("res://scenes/tableau/WidgetPairImpair.tscn")
const WidgetApproximation := preload("res://scenes/tableau/WidgetApproximation.tscn")
const WidgetTermeManquant := preload("res://scenes/tableau/WidgetTermeManquant.tscn")
const WidgetPlanCartesien := preload("res://scenes/tableau/WidgetPlanCartesien.tscn")
const WidgetPossibleImpossible := preload("res://scenes/tableau/WidgetPossibleImpossible.tscn")
const WidgetTableauPictogramme := preload("res://scenes/tableau/WidgetTableauPictogramme.tscn")
const WidgetFractions := preload("res://scenes/tableau/WidgetFractions.tscn")
const WidgetCroissantDecroissant := preload("res://scenes/tableau/WidgetCroissantDecroissant.tscn")

@onready var fond: ColorRect = %Fond
@onready var texture_fond: TextureRect = %TextureFond
@onready var label_xp: Label = %LabelXp
@onready var icone_berry_barre: TextureRect = %IconeBerryBarre
@onready var placeholder_berry_barre: Panel = %PlaceholderBerryBarre
@onready var label_compte_berries: Label = %LabelCompteBerries
@onready var bouton_quitter: Button = %BoutonQuitter
@onready var bouton_dev_reussir: Button = %BoutonDevReussir
@onready var label_titre: Label = %LabelTitre
@onready var label_question: Label = %LabelQuestion
@onready var label_feedback: Label = %LabelFeedback
@onready var zone_reponse: Control = %ZoneReponse
@onready var zone_joueur: Control = %ZoneJoueur
@onready var texture_joueur: TextureRectAnime = %TextureJoueur
@onready var placeholder_joueur: ColorRect = %PlaceholderJoueur
@onready var label_nom_joueur: Label = %LabelNomJoueur
@onready var zone_sauvage: Control = %ZoneSauvage
@onready var texture_sauvage: TextureRectAnime = %TextureSauvage
@onready var placeholder_sauvage: ColorRect = %PlaceholderSauvage
@onready var label_sauvage: Label = %LabelSauvage
@onready var label_nom_sauvage: Label = %LabelNomSauvage
@onready var zone_catch: Control = %ZoneCatch
@onready var texture_catch: TextureRectAnime = %TextureCatch
@onready var placeholder_catch: ColorRect = %PlaceholderCatch
@onready var timer_avance: Timer = %TimerAvance

@onready var panneau_resultats: PanelContainer = %PanneauResultats
@onready var label_resultats_titre: Label = %LabelResultatsTitre
@onready var label_resultats_details: Label = %LabelResultatsDetails
@onready var bouton_continuer: Button = %BoutonContinuer

var _matiere_id: String = ""
var _niveau_id: String = ""
var _questions: Array = []
var _contextes: Array = []
var _index_question: int = 0
var _score: int = 0
var _berries_gagnees: int = 0
var _xp_gagne: int = 0
var _widget_courant: Control = null
var _creature_sauvage_id: String = ""

## Valeur actuellement AFFICHEE par LabelXp (peut etre en retard sur
## SaveManager.get_xp_total() pendant l'anim "machine a sous") et jeton
## pour annuler proprement une anim en cours si une nouvelle arrive
## avant la fin — voir _animer_xp_gagne().
var _xp_affiche: int = 0
var _jeton_anim_xp: int = 0

func _ready() -> void:
	bouton_quitter.pressed.connect(func(): SceneTransition.changer_scene("res://scenes/SelectionNiveau.tscn"))
	bouton_dev_reussir.pressed.connect(_dev_completer_niveau)
	bouton_continuer.pressed.connect(_on_continuer_presse)
	timer_avance.one_shot = true
	timer_avance.wait_time = DUREE_FEEDBACK
	timer_avance.timeout.connect(_question_suivante)

	_matiere_id = GameState.matiere_courante_id
	_niveau_id = GameState.niveau_courant_id

	var matiere := DataManager.get_matiere_by_id(_matiere_id)
	var nom_niveau: String
	if _niveau_id == NIVEAU_ID_EXAMEN:
		_charger_examen()
		nom_niveau = "Examen"
	else:
		var niveau_data := DataManager.load_niveau("%s_%s" % [_matiere_id, _niveau_id])
		_questions = niveau_data.get("questions", [])
		var graphique: Dictionary = niveau_data.get("graphique", {})
		_contextes = []
		for i in range(_questions.size()):
			_contextes.append({"graphique": graphique})
		nom_niveau = String(niveau_data.get("nom", _niveau_id))
	label_titre.text = "%s - %s" % [String(matiere.get("nom", _matiere_id)), nom_niveau]
	_charger_fond()

	_actualiser_label_xp()
	_initialiser_barre_berries()
	_afficher_creature_joueur()
	_preparer_rencontre()
	_instancier_widget()
	_afficher_question(0)

func _actualiser_label_xp() -> void:
	# Invalide toute anim "machine a sous" en cours (jeton) pour qu'un
	# ancien decompte ne vienne pas ecraser cet affichage instantane.
	_jeton_anim_xp += 1
	_xp_affiche = SaveManager.get_xp_total()
	label_xp.text = "XP : %d" % _xp_affiche

## Fond d'ecran remplacable, PARTAGE par tous les tableaux (demande de
## Mike) — voir TableauAssetUtil / assets/ui/tableau/LISEZ-MOI.txt.
func _charger_fond() -> void:
	var texture := TableauAssetUtil.charger_fond()
	if texture != null:
		texture_fond.texture = texture
		texture_fond.visible = true
		fond.visible = false
	else:
		texture_fond.visible = false
		fond.visible = true

func _initialiser_barre_berries() -> void:
	var texture := BerryAssetUtil.charger_texture(SKIN_BERRY_BARRE)
	if texture != null:
		icone_berry_barre.texture = texture
		icone_berry_barre.visible = true
		placeholder_berry_barre.visible = false
	else:
		icone_berry_barre.visible = false
		placeholder_berry_barre.visible = true
	label_compte_berries.text = "x %d" % _berries_gagnees

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

	# Creature du JOUEUR affichee DE DOS pendant un tableau (creature
	# sauvage en face reste affichee de face, voir _afficher_creature_sauvage())
	# — demande de Mike, qui a depose les 4 variantes (cN/cN_glow/cbN/cbN_glow).
	var texture := SpriteUtil.charger_texture_dos_avec_glow(sprite_id, est_glow)
	if texture != null:
		texture_joueur.configurer_animation(texture, SpriteUtil.compter_frames(texture))
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
		texture_sauvage.configurer_animation(texture, SpriteUtil.compter_frames(texture))
		texture_sauvage.visible = true
		placeholder_sauvage.visible = false
	else:
		texture_sauvage.visible = false
		placeholder_sauvage.visible = true
		label_sauvage.text = sprite_id if not sprite_id.is_empty() else "?"

	label_nom_sauvage.text = String(names.get("stage1", _creature_sauvage_id))

## Construit _questions/_contextes pour l'examen (11e niveau) : priorise
## les questions ratees de cette matiere, complete avec des questions
## deja vues si besoin (voir ExamenUtil pour la decision de conception).
func _charger_examen() -> void:
	var ratees := SaveManager.get_questions_ratees(_matiere_id)
	var pool_vues := _construire_pool_questions_vues()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var entrees := ExamenUtil.construire_questions(ratees, pool_vues, rng)
	_questions = []
	_contextes = []
	for entree in entrees:
		_questions.append(entree["question"])
		_contextes.append(entree["contexte"])

## Pool de secours pour l'examen : toutes les questions des niveaux DEJA
## TENTES (debloques) de cette matiere, chacune avec le contexte
## (graphique) de son niveau d'origine.
func _construire_pool_questions_vues() -> Array:
	var pool := []
	var progression := SaveManager.get_progression_matiere(_matiere_id)
	var niveaux_progression: Dictionary = progression.get("niveaux", {})
	for numero in range(1, NB_NIVEAUX + 1):
		var niveau_id := "niveau_%02d" % numero
		if not niveaux_progression.has(niveau_id):
			continue
		var niveau_data := DataManager.load_niveau("%s_%s" % [_matiere_id, niveau_id])
		var graphique: Dictionary = niveau_data.get("graphique", {})
		for question in niveau_data.get("questions", []):
			pool.append({"question": question, "contexte": {"graphique": graphique}})
	return pool

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
	_widget_courant.configurer(_questions[index], _contextes[index])

func _on_reponse_donnee(correcte: bool) -> void:
	if correcte:
		_score += 1
		SaveManager.add_xp(XP_PAR_BONNE_REPONSE)
		SaveManager.ajouter_berry()
		_berries_gagnees += 1
		_xp_gagne += XP_PAR_BONNE_REPONSE
		label_feedback.text = "Bonne reponse ! +%d XP, +1 berry" % XP_PAR_BONNE_REPONSE
		label_feedback.modulate = Color(0.4, 0.9, 0.5, 1)
		_animer_xp_gagne(SaveManager.get_xp_total())
		_animer_gain_berry()
	else:
		label_feedback.text = "Pas tout a fait..."
		label_feedback.modulate = Color(0.95, 0.5, 0.4, 1)
		# Alimente le pool de l'examen (11e niveau) de cette matiere, qu'on
		# soit dans un niveau normal ou dans l'examen lui-meme — une
		# question ratee dans l'examen reste a pratiquer.
		SaveManager.ajouter_question_ratee(_matiere_id, _questions[_index_question], _contextes[_index_question])

	# Seuil en pourcentage, coherent avec _terminer_tableau() plus bas
	# (l'examen peut avoir moins de 10 questions).
	var total := _questions.size()
	var est_derniere_question := _index_question == total - 1
	var reussi_final := est_derniere_question and total > 0 and _score >= ceili(total * RATIO_REUSSITE)

	if reussi_final:
		# Derniere reponse ET tableau reussi (>=70%%, demande de Mike) :
		# PAS d'anim d'attaque, remplacee par la sequence de capture
		# (catch.gif) qui enchaine elle-meme sur l'ecran de resultats —
		# timer_avance n'est donc PAS demarre ici (voir _jouer_sequence_capture()).
		_jouer_sequence_capture()
	else:
		if correcte:
			AudioManager.jouer_son_attaque()
			_lancer_impact_combat_differe()
			timer_avance.start(DUREE_FEEDBACK_AVEC_ATTAQUE)
		else:
			timer_avance.start()

## --- Animation d'impact (bonne reponse) : la creature du joueur charge
## la creature sauvage, impact + recul, flash blanc sur la sauvage. Utilise
## tween.chain() (pas de set_parallel(false)/true en alternance, voir piege
## documente dans CLAUDE.md) et jamais tween_method()+bind() (autre piege
## documente, voir l'anim XP plus bas) : juste tween_property()/tween_callback()
## simples, ordre garanti.
## Attend DELAI_AVANT_ATTAQUE (le son d'attaque, lui, a deja demarre
## immediatement dans _on_reponse_donnee()) avant de lancer l'anim.
func _lancer_impact_combat_differe() -> void:
	await get_tree().create_timer(DELAI_AVANT_ATTAQUE).timeout
	_animer_impact_combat()

func _animer_impact_combat() -> void:
	var position_repos := zone_joueur.position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(zone_joueur, "position:x", position_repos.x + DISTANCE_LUNGE, DUREE_LUNGE)
	tween.chain().tween_callback(_declencher_impact)
	tween.chain().tween_property(zone_joueur, "position:x", position_repos.x, DUREE_RECOIL).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _declencher_impact() -> void:
	if texture_sauvage.material is ShaderMaterial:
		var tween_flash := create_tween()
		tween_flash.tween_property(texture_sauvage.material, "shader_parameter/intensite", 1.0, DUREE_FLASH * 0.3)
		tween_flash.chain().tween_property(texture_sauvage.material, "shader_parameter/intensite", 0.0, DUREE_FLASH * 0.7)
	var position_repos_sauvage := zone_sauvage.position
	var tween_recul := create_tween()
	tween_recul.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_recul.tween_property(zone_sauvage, "position:x", position_repos_sauvage.x + 20.0, 0.06)
	tween_recul.chain().tween_property(zone_sauvage, "position:x", position_repos_sauvage.x, 0.18)

## --- Sequence de capture (derniere reponse d'un tableau reussi) : lance
## catch.gif depuis le coin bas-gauche vers la creature sauvage en legere
## courbe, le joue une fois, aspire/retrecit la creature sauvage vers les
## 3/4 de la lecture, puis affiche l'ecran de resultats. Voir les
## constantes en tete de fichier pour les durees. N'appelle JAMAIS
## timer_avance ici : c'est cette sequence elle-meme qui termine le
## tableau (_terminer_tableau()) une fois finie.
func _jouer_sequence_capture() -> void:
	AudioManager.jouer_son_capture()

	var feuille := SpriteUtil.charger_texture_catch()
	var nb_frames := SpriteUtil.compter_frames(feuille)
	zone_catch.visible = true
	if feuille != null:
		texture_catch.configurer_animation_unique(feuille, nb_frames)
		texture_catch.visible = true
		placeholder_catch.visible = false
	else:
		texture_catch.visible = false
		placeholder_catch.visible = true

	var taille_ecran := get_viewport_rect().size
	var depart := Vector2(MARGE_DEPART_CATCH, taille_ecran.y - zone_catch.size.y - MARGE_DEPART_CATCH)
	var arrivee := zone_sauvage.global_position + zone_sauvage.size / 2.0 - zone_catch.size / 2.0
	var sommet := depart.lerp(arrivee, 0.5) + Vector2(0.0, -HAUTEUR_ARC_LANCER_CATCH)
	zone_catch.global_position = depart

	# Legere courbe vers le haut : 2 segments (vers le sommet, puis vers
	# la cible) plutot qu'une vraie parabole — evite tween_method()+bind()
	# (piege documente dans CLAUDE.md), suffisant visuellement pour un
	# "lancer" rapide.
	var tween_lancer := create_tween()
	tween_lancer.set_trans(Tween.TRANS_SINE)
	tween_lancer.tween_property(zone_catch, "global_position", sommet, DUREE_LANCER_CATCH * 0.5).set_ease(Tween.EASE_OUT)
	tween_lancer.chain().tween_property(zone_catch, "global_position", arrivee, DUREE_LANCER_CATCH * 0.5).set_ease(Tween.EASE_IN)
	await tween_lancer.finished

	# Duree reelle du gif (frames / fps) pour placer precisement le
	# moment "environ 3/4" de la lecture ou la creature sauvage doit etre
	# aspiree — repli sur une petite duree fixe si le gif n'est pas
	# encore depose (placeholder affiche, rien a synchroniser).
	var duree_gif := (nb_frames / TextureRectAnime.FPS_PAR_DEFAUT) if feuille != null else DUREE_LANCER_CATCH
	await get_tree().create_timer(duree_gif * FRACTION_ABSORPTION_GIF).timeout
	_absorber_creature_sauvage()
	await get_tree().create_timer(DUREE_ABSORPTION_SAUVAGE).timeout

	# Laisse le reste du gif (25%% restants) se terminer et se figer sur
	# sa derniere frame (configurer_animation_unique() ne boucle jamais,
	# voir TextureRectAnime) avant d'enchainer sur l'ecran de resultats.
	if feuille != null:
		var reste := duree_gif * (1.0 - FRACTION_ABSORPTION_GIF) - DUREE_ABSORPTION_SAUVAGE
		if reste > 0.0:
			await get_tree().create_timer(reste).timeout

	AudioManager.jouer_son_reussite()
	_terminer_tableau()

## Retrecit et "aspire" la creature sauvage vers le centre de catch.gif,
## puis la cache. Un seul groupe parallele (jamais de set_parallel()
## rebascule a false/true, voir piege documente dans CLAUDE.md) suivi
## d'un .chain() pour le callback final qui cache la creature.
func _absorber_creature_sauvage() -> void:
	zone_sauvage.pivot_offset = zone_sauvage.size / 2.0
	var position_cible := zone_catch.global_position + zone_catch.size / 2.0 - zone_sauvage.size / 2.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(zone_sauvage, "global_position", position_cible, DUREE_ABSORPTION_SAUVAGE)
	tween.tween_property(zone_sauvage, "scale", Vector2.ZERO, DUREE_ABSORPTION_SAUVAGE)
	tween.chain().tween_callback(func(): zone_sauvage.visible = false)

## --- Animations de gain (XP "slot machine" + berry qui "pop" et vole
## jusqu'a la barre) : Phase 8, demande de Mike, une seule fois par
## bonne reponse. ---

## Anime le compteur d'XP jusqu'a "xp_cible" en l'incrementant d'UNE
## UNITE a la fois (effet "machine a sous" : les chiffres defilent
## rapidement, pas un lerp lisse — corrige suite au retour de Mike).
##
## Repart de _xp_affiche (la valeur reellement affichee a l'ecran, pas
## necessairement SaveManager.get_xp_total() si une anim precedente est
## encore en cours) plutot que de "xp_avant" capture au moment de
## l'appel : si une 2e bonne reponse arrive avant la fin de l'anim de la
## 1ere, _jeton_anim_xp invalide proprement la boucle EN COURS (elle
## s'arrete au prochain increment plutot que de continuer en parallele),
## et la NOUVELLE boucle reprend le compte la ou l'affichage en est
## reellement — jamais de saut incoherent ni de retour en arriere.
##
## (Bug precedent trouve ici : `tween_method(...).bind(xp_avant, xp_apres)`
## -- Callable.bind() AJOUTE ses arguments APRES ceux fournis par
## l'appelant, pas avant. tween_method() appelait donc la fonction avec
## (t, xp_avant, xp_apres) alors qu'elle attendait (xp_avant, xp_apres, t)
## : "t" (0.0-1.0) se retrouvait interprete comme le premier XP, et
## xp_apres comme le "t" de lerpf(), d'ou des sauts enormes ou negatifs.
## La version ci-dessous n'utilise plus tween_method()/bind() pour
## eviter completement cette classe de piege.)
func _animer_xp_gagne(xp_cible: int) -> void:
	label_xp.pivot_offset = label_xp.size / 2.0
	_jeton_anim_xp += 1
	var mon_jeton := _jeton_anim_xp

	var tween_pop := create_tween()
	tween_pop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_pop.tween_property(label_xp, "scale", Vector2(1.25, 1.25), 0.1)
	tween_pop.chain().tween_property(label_xp, "scale", Vector2.ONE, 0.15)

	while _xp_affiche < xp_cible:
		if mon_jeton != _jeton_anim_xp:
			return
		_xp_affiche += 1
		label_xp.text = "XP : %d" % _xp_affiche
		await get_tree().create_timer(PAS_ANIM_XP).timeout

## Fait "pop" une berry (skin fixe, voir SKIN_BERRY_BARRE) pres du
## message de feedback, puis la fait voler jusqu'a l'icone de la barre
## de berries, ou elle disparait en incrementant le compteur.
func _animer_gain_berry() -> void:
	var texture := BerryAssetUtil.charger_texture(SKIN_BERRY_BARRE)
	var berry_volante: Control
	if texture != null:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		berry_volante = rect
	else:
		var rect := ColorRect.new()
		rect.color = BerryAssetUtil.couleur_placeholder(SKIN_BERRY_BARRE)
		berry_volante = rect

	berry_volante.size = Vector2(TAILLE_BERRY_VOLANTE, TAILLE_BERRY_VOLANTE)
	berry_volante.pivot_offset = Vector2(TAILLE_BERRY_VOLANTE, TAILLE_BERRY_VOLANTE) / 2.0
	berry_volante.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(berry_volante)

	var depart := label_feedback.global_position + label_feedback.size / 2.0 - Vector2(TAILLE_BERRY_VOLANTE, TAILLE_BERRY_VOLANTE) / 2.0
	var arrivee := icone_berry_barre.global_position + icone_berry_barre.size / 2.0 - Vector2(TAILLE_BERRY_VOLANTE, TAILLE_BERRY_VOLANTE) / 2.0
	berry_volante.global_position = depart
	berry_volante.scale = Vector2.ZERO

	var tween := create_tween()
	tween.tween_property(berry_volante, "scale", Vector2(1.3, 1.3), DUREE_POP_BERRY).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(berry_volante, "scale", Vector2.ONE, DUREE_POP_BERRY * 0.6)
	tween.chain().tween_interval(DUREE_PAUSE_BERRY)
	tween.chain().set_parallel(true)
	tween.tween_property(berry_volante, "global_position", arrivee, DUREE_VOL_BERRY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(berry_volante, "scale", Vector2(0.35, 0.35), DUREE_VOL_BERRY)
	tween.chain().tween_callback(func():
		berry_volante.queue_free()
		label_compte_berries.text = "x %d" % _berries_gagnees
	)

func _question_suivante() -> void:
	_afficher_question(_index_question + 1)

## Bouton de dev (a cote de Quitter) : complete instantanement le tableau
## a 100%% (score max) pour accelerer les tests manuels de Mike — meme
## chemin que _terminer_tableau() (bonus XP, capture, deblocage du
## niveau suivant), juste sans jouer les questions une par une.
func _dev_completer_niveau() -> void:
	timer_avance.stop()
	_score = _questions.size()
	_index_question = _questions.size()
	_terminer_tableau()

func _terminer_tableau() -> void:
	# Seuils en pourcentage (70% / 80%) plutot qu'un compte fixe sur 10 :
	# l'examen peut avoir MOINS de 10 questions si le pool disponible
	# (erreurs + questions deja vues) n'en fournit pas assez (voir
	# ExamenUtil) — un niveau normal a toujours exactement 10 questions,
	# donc ceili(10*0.7)=7 et ceili(10*0.8)=8, identique au comportement
	# d'avant cette generalisation.
	var total := _questions.size()
	var reussi: bool = total > 0 and _score >= ceili(total * RATIO_REUSSITE)
	var bonus := 0
	if total > 0 and _score >= ceili(total * RATIO_BONUS):
		bonus = BONUS_XP
		SaveManager.add_xp(BONUS_XP)
		_xp_gagne += BONUS_XP

	SaveManager.set_progression_niveau(_matiere_id, _niveau_id, reussi, _score, true, total)
	if reussi and _niveau_id != NIVEAU_ID_EXAMEN:
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
		if _niveau_id != NIVEAU_ID_EXAMEN:
			lignes.append("Le niveau suivant est debloque !")
	else:
		lignes.append("Il faut au moins 70%% pour reussir. Retente quand tu veux !")
	label_resultats_details.text = "\n".join(lignes)

func _on_continuer_presse() -> void:
	SceneTransition.changer_scene("res://scenes/SelectionNiveau.tscn")
