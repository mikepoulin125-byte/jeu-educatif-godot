class_name BerryAssetUtil
extends RefCounted
## Resout le skin visuel d'une berry (assets/ui/berries/berryN.png, N de
## 1 a 10). Voir assets/ui/berries/LISEZ-MOI.txt.

const NB_SKINS := 10
const BERRIES_DIR := "res://assets/ui/berries/"

static func chemin_skin(skin: int) -> String:
	return BERRIES_DIR + "berry" + str(skin) + ".png"

static func charger_texture(skin: int) -> Texture2D:
	var chemin := chemin_skin(skin)
	if not FileAccess.file_exists(chemin):
		return null
	return load(chemin) as Texture2D

## Couleur de secours distincte par skin (placeholder tant que l'image
## n'existe pas), pour que les 10 skins restent visuellement distincts
## meme sans art final.
static func couleur_placeholder(skin: int) -> Color:
	var teinte: float = float(skin - 1) / float(NB_SKINS)
	return Color.from_hsv(teinte, 0.55, 0.95, 1.0)

static func skin_aleatoire() -> int:
	return randi_range(1, NB_SKINS)
