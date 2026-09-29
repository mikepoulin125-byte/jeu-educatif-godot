class_name MenuAssetUtil
extends RefCounted
## Resout les images remplaçables de l'ecran-titre (assets/ui/menu/), sur
## le meme principe que SpriteUtil / UiIconUtil : si le fichier attendu
## n'existe pas encore, retourne null et l'appelant affiche un placeholder.
## Voir assets/ui/menu/LISEZ-MOI.txt pour les noms de fichiers et
## dimensions attendues.

const MENU_DIR := "res://assets/ui/menu/"
const NOM_FOND := "fond_menu.png"
const NOM_LOGO := "logo_menu.png"
const NOM_VIDEO_FOND := "fond_menu.ogv"

static func charger_fond() -> Texture2D:
	return _charger(NOM_FOND)

static func charger_logo() -> Texture2D:
	return _charger(NOM_LOGO)

## Fond video (prioritaire sur charger_fond() si present). Godot ne lit
## nativement que l'Ogg Theora (.ogv) — pas le mp4/h264 — voir
## assets/ui/menu/LISEZ-MOI.txt pour la commande de conversion.
static func charger_video_fond() -> VideoStream:
	var chemin := MENU_DIR + NOM_VIDEO_FOND
	if not FileAccess.file_exists(chemin):
		return null
	return load(chemin) as VideoStream

static func _charger(nom_fichier: String) -> Texture2D:
	var chemin := MENU_DIR + nom_fichier
	if not FileAccess.file_exists(chemin):
		return null
	return load(chemin) as Texture2D
