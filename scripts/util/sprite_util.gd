class_name SpriteUtil
extends RefCounted
## Utilitaire partage : resout un id de sprite ("c1", "c42"...) vers le
## fichier PNG reel s'il existe deja dans assets/creatures/, sinon signale
## qu'il faut afficher un placeholder. Voir section 3 de la spec : le jeu
## doit fonctionner avec des placeholders avant l'import des vraies images.
##
## Phase 8 : les sprites de creatures sont fournis par Mike en GIF anime
## (assets/creatures/cN.gif), convertis automatiquement (voir
## lancer_jeu.bat + scripts/tools/convertir_gifs.ps1) en une
## planche PNG cote a cote de frames carrees AVANT que le jeu ne demarre —
## Godot ne lit pas nativement les GIF animes (verifie sur cette version :
## aucune classe/methode liee au GIF dans l'API, contrairement a
## AnimatedTexture/SpriteFrames qui existent mais ne decodent rien
## eux-memes). charger_texture() continue donc de charger un simple .png
## (inchange), et compter_frames() deduit le nombre de frames de la
## planche a partir de ses seules dimensions (largeur / hauteur, puisque
## chaque frame est justement rendue carree par l'outil de conversion) —
## aucun fichier de metadonnees separe necessaire. Un vieux sprite
## statique (une seule image carree, jamais reconverti depuis un GIF)
## continue de fonctionner normalement : compter_frames() renvoie alors 1,
## et TextureRectAnime.configurer_animation() l'affiche simplement comme
## une image fixe, sans animation.

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

## Id du sprite "vu de dos" correspondant (creature du JOUEUR affichee de
## dos pendant un tableau — Mike a depose les 151 creatures en 4
## variantes : face "cN", face+glow "cN_glow", dos "cbN", dos+glow
## "cbN_glow") : meme dossier, "c" remplace par "cb". Ex.: "c1" -> "cb1".
static func id_dos(sprite_id: String) -> String:
	if sprite_id.begins_with("c"):
		return "cb" + sprite_id.substr(1)
	return sprite_id

## Sprite de dos + glow si applicable (voir charger_texture_avec_glow()),
## avec repli sur la version DE FACE si la version de dos n'existe pas
## encore pour cette creature (transition de contenu plus douce le temps
## que Mike termine de deposer les 151 x 4 variantes, plutot qu'un
## placeholder vide).
static func charger_texture_dos_avec_glow(sprite_id: String, est_glow: bool) -> Texture2D:
	var texture_dos := charger_texture_avec_glow(id_dos(sprite_id), est_glow)
	if texture_dos != null:
		return texture_dos
	return charger_texture_avec_glow(sprite_id, est_glow)

const CHEMIN_CATCH := CREATURES_DIR + "catch.png"

## Sprite de l'effet "capture" (catch.gif, joue une seule fois vers la fin
## d'un tableau REUSSI, voir ecran_tableau.gd::_jouer_sequence_capture()) —
## meme dossier que les creatures, meme pipeline de conversion GIF -> PNG
## (convertir_gifs.ps1). Retourne null tant que Mike ne l'a pas depose (un
## placeholder s'affiche alors a la place, meme principe que partout
## ailleurs).
static func charger_texture_catch() -> Texture2D:
	if not FileAccess.file_exists(CHEMIN_CATCH):
		return null
	return load(CHEMIN_CATCH) as Texture2D

## Deduit le nombre de frames d'une planche de sprites a partir de ses
## dimensions (largeur / hauteur, chaque frame etant carree — voir
## convertir_gifs_creatures.ps1). Renvoie 1 pour une image carree
## classique (sprite statique, pas encore reconverti depuis un GIF) ou
## si la texture est nulle.
static func compter_frames(texture: Texture2D) -> int:
	if texture == null:
		return 1
	var hauteur := texture.get_height()
	if hauteur <= 0:
		return 1
	return maxi(1, roundi(float(texture.get_width()) / float(hauteur)))
