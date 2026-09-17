class_name AnimMathUtil
extends RefCounted
## Fonctions pures (sans dependance a l'arbre de scene) pour les
## animations de l'ecran de chargement, extraites ici pour etre testables
## sans instancier de scene ni faire tourner de moteur de rendu.

const SECONDES_PAR_TOUR := 2.0
const VITESSE_ANGULAIRE := TAU / SECONDES_PAR_TOUR  # rad/s

const AMPLITUDE_POINT := 8.0
const PERIODE_POINT := 0.6
const DECALAGE_ENTRE_POINTS := 0.1

## Angle de rotation (radians, normalise dans [0, TAU)) apres "temps" secondes
## de rotation continue a raison d'un tour complet toutes les 2 secondes.
static func rotation_apres(temps: float) -> float:
	return fmod(temps * VITESSE_ANGULAIRE, TAU)

## Decalage vertical (en pixels, toujours <= 0, donc vers le haut) du
## point d'indice "index" (0, 1 ou 2) au temps "temps" : un rebond
## periodique, avec un decalage de phase de 100ms entre chaque point
## pour creer un effet de vague.
static func decalage_point_chargement(temps: float, index: int) -> float:
	var phase: float = temps - index * DECALAGE_ENTRE_POINTS
	return -abs(sin(phase * TAU / PERIODE_POINT)) * AMPLITUDE_POINT
