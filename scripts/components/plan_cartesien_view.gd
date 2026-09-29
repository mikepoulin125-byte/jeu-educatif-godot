class_name PlanCartesienView
extends Control
## Dessin partage d'un plan cartesien (quadrant positif) : axes flesches,
## quadrillage et graduations numerotees. Meme visuel reutilise par TOUS
## les tableaux du badge "plan_cartesien" (voir CLAUDE.md) meme quand la
## mecanique differe d'un tableau a l'autre (completer une graduation,
## plus tard cliquer une intersection...) - purement decoratif/visuel,
## aucune interaction geree ici.
##
## configurer() recoit, pour chaque axe, un tableau d'etiquettes (une par
## graduation, dans l'ordre 1..taille) : null = graduation non dessinee
## du tout, sinon le texte affiche (ex. "3"). Un indice de graduation par
## axe peut etre mis en evidence (cercle rouge) pour indiquer a l'enfant
## OU se trouve le nombre manquant a trouver.

const MARGE := 56.0
const DEBORD_FLECHE := 26.0
const COULEUR_AXE := Color(0.05, 0.05, 0.05)
const COULEUR_GRILLE := Color(0.68, 0.86, 0.93)
const COULEUR_MARQUE := Color(0.86, 0.16, 0.16)
const COULEUR_POINT := Color(0.1, 0.1, 0.1)
const TAILLE_POLICE := 18
const TAILLE_POLICE_NOM_POINT := 22

var taille: int = 5
var etiquettes_x: Array = []
var etiquettes_y: Array = []
var indice_x_marque: int = -1
var indice_y_marque: int = -1
var point: Dictionary = {}

## "etiquettes_x"/"etiquettes_y" : Array de taille "p_taille", une entree
## par graduation (null = rien dessine a cette graduation).
## "indice_x_marque"/"indice_y_marque" : indice (0-based) de la
## graduation a mettre en evidence sur chaque axe, -1 = aucune.
## "p_point" optionnel : {"x":int,"y":int,"nom":String} - dessine un
## point avec ses pointilles jusqu'aux deux axes (ex. le point A de
## l'exemple de Mike), independant des graduations/marques ci-dessus.
func configurer(p_taille: int, p_etiquettes_x: Array, p_etiquettes_y: Array, p_indice_x_marque: int = -1, p_indice_y_marque: int = -1, p_point: Dictionary = {}) -> void:
	taille = maxi(1, p_taille)
	etiquettes_x = p_etiquettes_x
	etiquettes_y = p_etiquettes_y
	indice_x_marque = p_indice_x_marque
	indice_y_marque = p_indice_y_marque
	point = p_point
	queue_redraw()

func _pas() -> float:
	var cote := minf(size.x - MARGE - DEBORD_FLECHE, size.y - MARGE - DEBORD_FLECHE)
	return maxf(cote, 1.0) / float(taille)

func _origine() -> Vector2:
	return Vector2(MARGE, size.y - MARGE)

## (gx, gy) en unites de graduation -> position en pixels dans le noeud.
func _point_grille(gx: float, gy: float) -> Vector2:
	var pas := _pas()
	return _origine() + Vector2(gx * pas, -gy * pas)

## Version publique de _point_grille() : permet a un appelant (ex. le
## widget qui place une creature sur le plan) de positionner un noeud
## enfant a une coordonnee (x, y) exacte, sans dupliquer le calcul.
func point_vers_pixel(gx: float, gy: float) -> Vector2:
	return _point_grille(gx, gy)

## Inverse de point_vers_pixel() : convertit une position en pixels
## (locale a ce noeud) vers la coordonnee de graduation la plus proche,
## bornee a [0, taille] sur chaque axe (jamais de coordonnee negative ni
## hors grille). Utilise pour le glisser-depose (tableau "placer_point").
func pixel_vers_point(pixel: Vector2) -> Vector2i:
	var pas := _pas()
	var origine := _origine()
	var gx := roundi((pixel.x - origine.x) / pas)
	var gy := roundi((origine.y - pixel.y) / pas)
	return Vector2i(clampi(gx, 0, taille), clampi(gy, 0, taille))

func _draw() -> void:
	var pas := _pas()
	var origine := _origine()
	var pointe_x := _point_grille(taille, 0) + Vector2(DEBORD_FLECHE, 0)
	var pointe_y := _point_grille(0, taille) + Vector2(0, -DEBORD_FLECHE)
	var police := ThemeDB.fallback_font

	for i in range(1, taille + 1):
		draw_line(_point_grille(i, 0), _point_grille(i, taille), COULEUR_GRILLE, 2.0)
		draw_line(_point_grille(0, i), _point_grille(taille, i), COULEUR_GRILLE, 2.0)

	draw_line(origine, pointe_x, COULEUR_AXE, 3.0)
	draw_line(origine, pointe_y, COULEUR_AXE, 3.0)
	_dessiner_fleche(pointe_x, Vector2.RIGHT)
	_dessiner_fleche(pointe_y, Vector2.UP)

	for i in range(taille):
		var etiquette_x = etiquettes_x[i] if i < etiquettes_x.size() else null
		var etiquette_y = etiquettes_y[i] if i < etiquettes_y.size() else null
		var graduation := i + 1
		if etiquette_x != null:
			var pos_x := _point_grille(graduation, 0) + Vector2(-8, 26)
			draw_string(police, pos_x, str(etiquette_x), HORIZONTAL_ALIGNMENT_CENTER, -1, TAILLE_POLICE, COULEUR_AXE)
		if etiquette_y != null:
			var pos_y := _point_grille(0, graduation) + Vector2(-34, 6)
			draw_string(police, pos_y, str(etiquette_y), HORIZONTAL_ALIGNMENT_CENTER, -1, TAILLE_POLICE, COULEUR_AXE)
		if i == indice_x_marque:
			draw_circle(_point_grille(graduation, 0) + Vector2(0, 16), 13.0, COULEUR_MARQUE)
		if i == indice_y_marque:
			draw_circle(_point_grille(0, graduation) + Vector2(-18, 0), 13.0, COULEUR_MARQUE)

	if point.has("x") and point.has("y"):
		var px := float(point["x"])
		var py := float(point["y"])
		var p := _point_grille(px, py)
		_dessiner_pointilles(Vector2(origine.x, p.y), p)
		_dessiner_pointilles(Vector2(p.x, origine.y), p)
		draw_circle(p, 6.0, COULEUR_POINT)
		if point.has("nom"):
			draw_string(police, p + Vector2(10, -10), String(point["nom"]), HORIZONTAL_ALIGNMENT_LEFT, -1, TAILLE_POLICE_NOM_POINT, COULEUR_POINT)

func _dessiner_fleche(pointe: Vector2, direction: Vector2) -> void:
	var perpendiculaire := direction.orthogonal()
	var a := pointe - direction * 14.0 + perpendiculaire * 7.0
	var b := pointe - direction * 14.0 - perpendiculaire * 7.0
	draw_polygon([pointe, a, b], [COULEUR_AXE, COULEUR_AXE, COULEUR_AXE])

func _dessiner_pointilles(depart: Vector2, arrivee: Vector2) -> void:
	var distance := depart.distance_to(arrivee)
	if distance < 0.01:
		return
	var direction := (arrivee - depart) / distance
	var pas_tiret := 10.0
	var i := 0.0
	while i < distance:
		var a := depart + direction * i
		var b := depart + direction * minf(i + pas_tiret * 0.6, distance)
		draw_line(a, b, COULEUR_POINT, 2.0)
		i += pas_tiret
