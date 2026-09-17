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
