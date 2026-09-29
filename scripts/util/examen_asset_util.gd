class_name ExamenAssetUtil
extends RefCounted
## Resout l'icone du coin superieur droit de la carte "Examen" — UNE
## icone PAR MATIERE (confirme par Mike), reliee au meme "id" que celui
## deja utilise dans data/matieres.json / data/niveaux/*.json (ex.
## "pair_impair", "fractions"...) — voir assets/ui/examen/LISEZ-MOI.txt.
## Meme principe que UiIconUtil/SpriteUtil : null si le fichier n'existe
## pas encore, l'appelant affiche alors la carte sans icone.

const DOSSIER := "res://assets/ui/examen/"

static func chemin_icone(matiere_id: String) -> String:
	return DOSSIER + "exam_" + matiere_id + "_icon.png"

static func charger_icone(matiere_id: String) -> Texture2D:
	var chemin := chemin_icone(matiere_id)
	if not FileAccess.file_exists(chemin):
		return null
	return load(chemin) as Texture2D
