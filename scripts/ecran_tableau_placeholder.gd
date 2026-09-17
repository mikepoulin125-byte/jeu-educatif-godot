extends Control
## Placeholder Phase 6 (scenes de tableau, pas encore construites) :
## confirme que la navigation Hub -> SelectionNiveau -> ici fonctionne,
## et fournit deux boutons de debug pour simuler la fin d'un tableau
## (reussi ou echoue) afin de tester de bout en bout la logique de
## deblocage sequentiel des niveaux (deja disponible depuis la Phase 1,
## SaveManager.set_progression_niveau/est_niveau_debloque).
##
## A REMPLACER en Phase 6 par les 8 vraies mecaniques d'interaction
## (section 9 de la spec) ; la logique de fin de tableau ci-dessous
## (marquer reussi/echoue + debloquer le niveau suivant) est le
## comportement exact que chaque vraie scene de tableau devra reproduire
## a la fin de ses 10 questions.

const NB_NIVEAUX := 10
const SEUIL_REUSSITE := 7

@onready var label_info: Label = %LabelInfo
@onready var label_statut: Label = %LabelStatut
@onready var bouton_reussir: Button = %BoutonReussir
@onready var bouton_echouer: Button = %BoutonEchouer
@onready var bouton_retour: Button = %BoutonRetour

func _ready() -> void:
	var matiere := DataManager.get_matiere_by_id(GameState.matiere_courante_id)
	var nom_matiere: String = String(matiere.get("nom", GameState.matiere_courante_id))
	var niveau_data := DataManager.load_niveau("%s_%s" % [GameState.matiere_courante_id, GameState.niveau_courant_id])
	var nom_niveau: String = String(niveau_data.get("nom", GameState.niveau_courant_id))

	label_info.text = "%s\n%s\n\n(scene de tableau a construire en Phase 6)" % [nom_matiere, nom_niveau]

	bouton_reussir.pressed.connect(func(): _terminer_tableau(8))
	bouton_echouer.pressed.connect(func(): _terminer_tableau(4))
	bouton_retour.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/SelectionNiveau.tscn"))

func _terminer_tableau(score: int) -> void:
	var matiere_id := GameState.matiere_courante_id
	var niveau_id := GameState.niveau_courant_id
	var reussi: bool = score >= SEUIL_REUSSITE

	SaveManager.set_progression_niveau(matiere_id, niveau_id, reussi, score, true)

	if reussi:
		var numero_actuel: int = int(niveau_id.replace("niveau_", ""))
		if numero_actuel < NB_NIVEAUX:
			var niveau_suivant_id := "niveau_%02d" % (numero_actuel + 1)
			SaveManager.set_progression_niveau(matiere_id, niveau_suivant_id, false, 0, true)
		label_statut.text = "Reussi ! (%d/10) - niveau suivant debloque." % score
	else:
		label_statut.text = "Echoue (%d/10) - reessaie quand tu veux." % score
