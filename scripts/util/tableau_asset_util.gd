class_name TableauAssetUtil
extends RefCounted
## Resout le fond d'ecran remplacable de l'ecran de tableau (EcranTableau.tscn).
## UN SEUL fond, PARTAGE par tous les tableaux peu importe la matiere
## (change de decision : c'etait un fond par matiere, Mike a demande un
## fond unique a la place). Accepte plusieurs extensions usuelles
## (jpeg/jpg/png, essayees dans cet ordre) — Mike a depose un .jpeg.
## Meme principe que MenuAssetUtil/HubAssetUtil/DialogueIntroAssetUtil :
## retourne null si aucun fichier n'existe encore, l'appelant affiche
## alors le fond de couleur uni habituel.

const DOSSIER := "res://assets/ui/tableau/"
const EXTENSIONS: Array[String] = ["jpeg", "jpg", "png"]

## Chemin du fond reellement present sur disque, ou chaine vide si aucun
## des fichiers "fond.<extension>" n'existe encore.
static func chemin_fond() -> String:
	for extension in EXTENSIONS:
		var chemin: String = DOSSIER + "fond." + extension
		if FileAccess.file_exists(chemin):
			return chemin
	return ""

static func charger_fond() -> Texture2D:
	var chemin := chemin_fond()
	if chemin.is_empty():
		return null
	return load(chemin) as Texture2D
