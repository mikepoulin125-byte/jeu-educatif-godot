class_name ExamenUtil
extends RefCounted
## Logique pure de construction des 10 questions du "11e niveau" (examen)
## d'une matiere : priorise les questions ratees par le joueur a travers
## tous les niveaux de cette matiere, et complete avec des questions
## deja vues (n'importe quel niveau deja tente) si le pool de questions
## ratees ne suffit pas encore. Fonction pure (aucune dependance a
## SaveManager/DataManager) pour rester testable isolement — meme
## principe que RencontreUtil.
##
## Decision de conception (pas precisee explicitement par la demande de
## Mike) : si le contenu disponible (ratees + deja vues, sans doublon)
## est INFERIEUR a 10, l'examen se construit quand meme avec MOINS de
## 10 questions plutot que d'etre bloque — le seuil de reussite (70%)
## s'applique alors sur ce total reduit (voir ecran_tableau.gd). Ca reste
## coherent avec la philosophie "le jeu doit rester jouable avec un
## contenu partiel" deja appliquee partout ailleurs dans ce projet.

const NB_QUESTIONS_EXAMEN := 10

## "ratees" et "pool_vues" : Array de {"question": Dictionary, "contexte": Dictionary}.
static func construire_questions(ratees: Array, pool_vues: Array, rng: RandomNumberGenerator) -> Array:
	var choisies: Array = _melanger(ratees, rng)
	if choisies.size() > NB_QUESTIONS_EXAMEN:
		choisies = choisies.slice(0, NB_QUESTIONS_EXAMEN)

	if choisies.size() < NB_QUESTIONS_EXAMEN:
		for entree in _melanger(pool_vues, rng):
			if choisies.size() >= NB_QUESTIONS_EXAMEN:
				break
			if not choisies.has(entree):
				choisies.append(entree)

	return choisies

static func _melanger(tableau: Array, rng: RandomNumberGenerator) -> Array:
	var copie := tableau.duplicate()
	for i in range(copie.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = copie[i]
		copie[i] = copie[j]
		copie[j] = tmp
	return copie
