class_name HubAssetUtil
extends RefCounted
## Resout le visuel de gauche du Hub (contenu pas encore determine par
## Mike -- seul l'emplacement + le mecanisme de chargement sont en place
## pour l'instant). Voir assets/ui/hub/LISEZ-MOI.txt. Meme pipeline GIF
## -> planche PNG que les creatures (scripts/tools/convertir_gifs.ps1).
##
## Le visuel de droite (creature principale du joueur) ne passe pas par
## cet utilitaire : il reutilise SpriteUtil directement, comme partout
## ailleurs ou la creature principale est affichee (voir hub.gd).

const HUB_DIR := "res://assets/ui/hub/"
const NOM_GAUCHE := "gauche.png"

static func charger_gauche() -> Texture2D:
	var chemin := HUB_DIR + NOM_GAUCHE
	if not FileAccess.file_exists(chemin):
		return null
	return load(chemin) as Texture2D
