extends Control
## Widget "plan_cartesien" : grille cliquable (quadrant positif
## seulement), l'enfant clique la case (x,y) demandee. Simplification
## assumee par rapport au glisser-depose litteral de la spec (voir
## docs/phases/phase_06_scenes_tableau.md) : cliquer la bonne case
## remplit le meme objectif pedagogique (identifier des coordonnees) en
## restant simple et fiable a tester. Resout %Nom a la demande (voir
## widget_pair_impair.gd pour le pourquoi).

signal reponse_donnee(correcte: bool)

var _x_attendu: int = 0
var _y_attendu: int = 0
var _repondu: bool = false

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_x_attendu = int(question.get("x", 0))
	_y_attendu = int(question.get("y", 0))
	var taille: int = int(question.get("taille_grille", 5))
	var label_consigne: Label = %LabelConsigne
	label_consigne.text = "Place la creature en (%d, %d)" % [_x_attendu, _y_attendu]
	_repondu = false
	_construire_grille(taille)

func _construire_grille(taille: int) -> void:
	var grille: GridContainer = %Grille
	for enfant in grille.get_children():
		enfant.queue_free()
	grille.columns = taille
	# Rangee du haut = y le plus grand, pour un repere cartesien habituel.
	for y in range(taille - 1, -1, -1):
		for x in range(0, taille):
			var bouton := Button.new()
			bouton.custom_minimum_size = Vector2(36, 36)
			bouton.text = ""
			bouton.focus_mode = Control.FOCUS_NONE
			bouton.pressed.connect(_on_case_pressee.bind(x, y))
			grille.add_child(bouton)

func _on_case_pressee(x: int, y: int) -> void:
	if _repondu:
		return
	_repondu = true
	reponse_donnee.emit(x == _x_attendu and y == _y_attendu)
