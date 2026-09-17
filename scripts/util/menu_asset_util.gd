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

static func charger_fond() -> Texture2D:
	return _charger(NOM_FOND)

static func charger_logo() -> Texture2D:
	return _charger(NOM_LOGO)

static func _charger(nom_fichier: String) -> Texture2D:
	var chemin := MENU_DIR + nom_fichier
	if not FileAccess.file_exists(chemin):
		return null
	return load(chemin) as Texture2D
