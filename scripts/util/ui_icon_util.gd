class_name UiIconUtil
extends RefCounted
## Meme principe que SpriteUtil, mais pour les icones d'interface
## (assets/ui/*.png : icones de matiere, badges, etc.).

const UI_DIR := "res://assets/ui/"

static func chemin_icone(icone_id: String) -> String:
	return UI_DIR + icone_id + ".png"

static func icone_existe(icone_id: String) -> bool:
	if icone_id.is_empty():
		return false
	return FileAccess.file_exists(chemin_icone(icone_id))

static func charger_texture(icone_id: String) -> Texture2D:
	if not icone_existe(icone_id):
		return null
	return load(chemin_icone(icone_id)) as Texture2D
