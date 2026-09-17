class_name ChargementAssetUtil
extends RefCounted
## Meme principe que MenuAssetUtil : resout l'icone remplacable de l'ecran
## de chargement (assets/ui/chargement/icone_chargement.png).
## Voir assets/ui/chargement/LISEZ-MOI.txt.

const CHEMIN_ICONE := "res://assets/ui/chargement/icone_chargement.png"

static func charger_icone() -> Texture2D:
	if not FileAccess.file_exists(CHEMIN_ICONE):
		return null
	return load(CHEMIN_ICONE) as Texture2D
