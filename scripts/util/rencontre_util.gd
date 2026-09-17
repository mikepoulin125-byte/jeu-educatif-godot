class_name RencontreUtil
extends RefCounted
## Tirage au hasard de la creature sauvage d'un tableau (section 9.1 de
## la spec) : parmi les creatures non-evoluees jamais encore vues, sans
## repetition tant que toutes n'y sont pas passees. Fonction pure
## (prend les listes en parametres plutot que de lire SaveManager/
## DataManager directement) pour rester testable sans autoload.

## "toutes_ids" = DataManager.get_creatures_non_evoluees(),
## "deja_vues" = SaveManager.get_creatures_vues(). Si toutes les
## creatures ont deja ete vues, retire parmi l'ensemble complet (la
## spec ne precise pas explicitement ce cas, mais garantit qu'un tirage
## reste toujours possible plutot que de bloquer une fois le roster
## complet). Retourne "" si "toutes_ids" est vide (aucune creature
## definie dans creatures.json).
static func tirer_creature_sauvage(toutes_ids: Array, deja_vues: Array) -> String:
	if toutes_ids.is_empty():
		return ""
	var candidates: Array = []
	for id in toutes_ids:
		if not deja_vues.has(id):
			candidates.append(id)
	if candidates.is_empty():
		candidates = toutes_ids.duplicate()
	return String(candidates[randi() % candidates.size()])
