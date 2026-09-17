class_name SpriteUtil
extends RefCounted
## Utilitaire partage : resout un id de sprite ("c1", "c42"...) vers le
## fichier PNG reel s'il existe deja dans assets/creatures/, sinon signale
## qu'il faut afficher un placeholder. Voir section 3 de la spec : le jeu
## doit fonctionner avec des placeholders avant l'import des vraies images.

const CREATURES_DIR := "res://assets/creatures/"

static func chemin_sprite(sprite_id: String) -> String:
	return CREATURES_DIR + sprite_id + ".png"

static func sprite_existe(sprite_id: String) -> bool:
	if sprite_id.is_empty():
		return false
	return FileAccess.file_exists(chemin_sprite(sprite_id))

static func charger_texture(sprite_id: String) -> Texture2D:
	if not sprite_existe(sprite_id):
		return null
	return load(chemin_sprite(sprite_id)) as Texture2D

## Id du sprite "glow" correspondant (systeme de berries) : meme dossier,
## suffixe "_glow". Ex.: "c1" -> "c1_glow".
static func id_glow(sprite_id: String) -> String:
	return sprite_id + "_glow"

## Retourne le sprite glow si "est_glow" est vrai ET que le fichier existe
## deja, sinon retombe sur le sprite normal (jamais null si le sprite
## normal existe, meme quand le glow n'a pas encore ete depose par Mike).
static func charger_texture_avec_glow(sprite_id: String, est_glow: bool) -> Texture2D:
	if est_glow:
		var texture_glow := charger_texture(id_glow(sprite_id))
		if texture_glow != null:
			return texture_glow
	return charger_texture(sprite_id)

## Vrai seulement si "est_glow" est demande ET que le fichier glow reel
## n'existe pas encore (utile pour afficher un placeholder "glow"
## distinct du placeholder normal).
static func glow_manquant(sprite_id: String, est_glow: bool) -> bool:
	return est_glow and not sprite_existe(id_glow(sprite_id))
