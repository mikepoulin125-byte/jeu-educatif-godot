class_name DialogueIntroAssetUtil
extends RefCounted
## Resout le fond d'ecran remplacable de la boite de dialogue narrative
## (DialogueIntro.tscn, "Nouvelle partie"). Meme principe que
## MenuAssetUtil/HubAssetUtil : retourne null si le fichier n'existe pas
## encore, l'appelant affiche alors le fond de couleur uni habituel.

const CHEMIN_FOND := "res://assets/ui/dialogue_intro/fond.png"

static func charger_fond() -> Texture2D:
	if not FileAccess.file_exists(CHEMIN_FOND):
		return null
	return load(CHEMIN_FOND) as Texture2D
