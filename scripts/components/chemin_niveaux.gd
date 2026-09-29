class_name CheminNiveaux
extends Control
## Chemin de terre procedural (dessin vectoriel simple, aucun asset
## externe) reliant les cartes de niveau entre elles dans
## SelectionNiveau.tscn, esprit "carte de jeu" (ex. Pokemon) : une ligne
## sinueuse en pointilles, purement decorative (indicateur visuel de
## progression/connexion, jamais interactif — mouse_filter = IGNORE).
##
## definir_points() recoit le CENTRE de chaque carte de niveau a relier,
## dans l'ordre (niveau 1 -> 2 -> ... -> 10). Un segment courbe (Bezier
## quadratique, avec un leger "bombement" perpendiculaire au segment
## pour un trace naturel plutot qu'une ligne droite) est dessine entre
## chaque paire consecutive. La carte "Examen" n'est PAS reliee au
## chemin (elle est visuellement separee, voir selection_niveau.gd).

const COULEUR_CHEMIN := Color(0.62, 0.47, 0.32, 0.9)
const COULEUR_CONTOUR := Color(0.42, 0.31, 0.2, 0.9)
const LARGEUR_TIRET := 10.0
const LONGUEUR_TIRET := 14.0
const ESPACE_TIRET := 10.0
const BOMBEMENT := 24.0

var _points: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## "points" : Array[Vector2], un point par carte de niveau, dans l'ordre.
func definir_points(points: Array) -> void:
	_points = points
	queue_redraw()

func _draw() -> void:
	for i in range(_points.size() - 1):
		_dessiner_segment(_points[i], _points[i + 1])

func _dessiner_segment(a: Vector2, b: Vector2) -> void:
	var milieu := (a + b) / 2.0
	var direction := (b - a)
	if direction.length() < 0.01:
		return
	var perpendiculaire := direction.normalized().orthogonal()
	# Alterne le sens du "bombement" pour un trace qui ondule plutot que
	# de toujours courber du meme cote (aspect plus naturel/sinueux).
	var signe := 1.0 if int(a.x + a.y) % 2 == 0 else -1.0
	var point_controle := milieu + perpendiculaire * BOMBEMENT * signe

	var longueur_courbe := a.distance_to(point_controle) + point_controle.distance_to(b)
	var nb_segments := maxi(8, int(longueur_courbe / 6.0))
	var courbe := PackedVector2Array()
	for i in range(nb_segments + 1):
		var t := float(i) / float(nb_segments)
		courbe.append(a.bezier_interpolate(point_controle, point_controle, b, t))

	_dessiner_pointilles(courbe)

## Dessine une suite de petits traits (tirets) le long d'une polyligne,
## pour un effet "chemin de terre pointille" plutot qu'une ligne pleine.
func _dessiner_pointilles(courbe: PackedVector2Array) -> void:
	var distance_parcourue := 0.0
	var dessine := true
	var segment_debut := courbe[0]

	for i in range(1, courbe.size()):
		var point_a := courbe[i - 1]
		var point_b := courbe[i]
		var pas := point_a.distance_to(point_b)
		var parcouru_segment := 0.0

		while parcouru_segment < pas:
			var restant_cycle := (LONGUEUR_TIRET if dessine else ESPACE_TIRET) - distance_parcourue
			var avance := minf(restant_cycle, pas - parcouru_segment)
			var t0 := parcouru_segment / pas
			var t1 := (parcouru_segment + avance) / pas
			if dessine:
				draw_line(point_a.lerp(point_b, t0), point_a.lerp(point_b, t1), COULEUR_CONTOUR, LARGEUR_TIRET + 3.0)
				draw_line(point_a.lerp(point_b, t0), point_a.lerp(point_b, t1), COULEUR_CHEMIN, LARGEUR_TIRET)

			parcouru_segment += avance
			distance_parcourue += avance
			if distance_parcourue >= (LONGUEUR_TIRET if dessine else ESPACE_TIRET):
				distance_parcourue = 0.0
				dessine = not dessine
