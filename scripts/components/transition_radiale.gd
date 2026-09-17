class_name TransitionRadiale
extends ColorRect
## Voile blanc plein ecran avec degrade radial anime (voir
## shaders/transition_radiale_blanc.gdshader). Reutilisable partout ou
## une transition "vers/depuis le blanc, bords en premier" est needed :
## menu -> ecran de chargement -> jeu.
##
## definir_progression(0.0) = invisible, definir_progression(1.0) =
## ecran entierement blanc, degrade radial entre les deux (bords
## atteints avant le centre).

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_appliquer_taille_ecran()
	resized.connect(_appliquer_taille_ecran)

func _appliquer_taille_ecran() -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("taille_ecran", size)

func definir_progression(valeur: float) -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("progression", valeur)

## Anime "progression" de "depart" vers "arrivee" sur "duree" secondes.
## A utiliser avec `await` pour enchainer une action une fois la
## transition terminee.
func animer(depart: float, arrivee: float, duree: float) -> void:
	definir_progression(depart)
	var tween := create_tween()
	tween.tween_property(material, "shader_parameter/progression", arrivee, duree).set_trans(Tween.TRANS_SINE)
	await tween.finished
