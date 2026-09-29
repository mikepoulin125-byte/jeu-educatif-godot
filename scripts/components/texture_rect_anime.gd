class_name TextureRectAnime
extends TextureRect
## TextureRect qui affiche une planche de sprites (plusieurs frames carrees
## cote a cote dans un seul fichier) comme une animation en boucle, au lieu
## d'une image statique. Utilise pour les sprites de creatures depuis la
## migration GIF de la Phase 8 (voir SpriteUtil, en tete de fichier, pour
## le detail du pipeline GIF -> planche PNG).
##
## Reste un simple affichage statique si nb_frames <= 1 (compatibilite
## avec un sprite carre classique jamais reconverti depuis un GIF) : pas
## de Timer cree dans ce cas, aucun cout ajoute.
##
## Script attache directement sur le noeud TextureRect existant (comme
## les autres composants de ce projet) — pas besoin d'un noeud/scene
## separe : configurer_animation() fonctionne des l'instanciation, sans
## attendre _ready().

## x3 (etait 8.0) sur demande de Mike : tous les affichages de GIF du
## jeu utilisent ce defaut (aucun appelant ne passe de "fps" explicite,
## voir grep de configurer_animation() dans CLAUDE.md), donc ce seul
## changement accelere toutes les creatures animees a la fois.
const FPS_PAR_DEFAUT := 24.0

## Emis une seule fois, quand une animation lancee via
## configurer_animation_unique() atteint sa derniere frame et s'y fige
## (voir configurer_animation_unique()).
signal animation_terminee

var _feuille: Texture2D
var _taille_frame: int = 0
var _nb_frames: int = 1
var _frame_actuelle: int = 0
var _minuteur: Timer
var _boucle: bool = true

func configurer_animation(feuille: Texture2D, nb_frames: int, fps: float = FPS_PAR_DEFAUT) -> void:
	_boucle = true
	_demarrer(feuille, nb_frames, fps)

## Variante "joue une seule fois" (pas de boucle) : utilisee pour des
## effets ponctuels (ex. catch.gif de la sequence de capture en fin de
## tableau reussi) plutot que les creatures (toujours en boucle via
## configurer_animation()). Se fige sur la DERNIERE frame et emet
## "animation_terminee" une fois la planche parcourue une fois (clamp,
## jamais de retour a la frame 0 tout seul).
func configurer_animation_unique(feuille: Texture2D, nb_frames: int, fps: float = FPS_PAR_DEFAUT) -> void:
	_boucle = false
	_demarrer(feuille, nb_frames, fps)
	if feuille != null and nb_frames <= 1:
		animation_terminee.emit()

func _demarrer(feuille: Texture2D, nb_frames: int, fps: float) -> void:
	_arreter()
	if feuille == null:
		texture = null
		return
	if nb_frames <= 1:
		texture = feuille
		return

	_feuille = feuille
	_nb_frames = nb_frames
	_taille_frame = feuille.get_height()
	_frame_actuelle = 0
	_afficher_frame(0)

	if _minuteur == null:
		_minuteur = Timer.new()
		add_child(_minuteur)
		_minuteur.timeout.connect(_frame_suivante)
	_minuteur.wait_time = 1.0 / fps
	_minuteur.start()

func _afficher_frame(index: int) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = _feuille
	atlas.region = Rect2(index * _taille_frame, 0, _taille_frame, _taille_frame)
	texture = atlas

func _frame_suivante() -> void:
	if _boucle:
		_frame_actuelle = (_frame_actuelle + 1) % _nb_frames
		_afficher_frame(_frame_actuelle)
		return
	if _frame_actuelle >= _nb_frames - 1:
		_minuteur.stop()
		return
	_frame_actuelle += 1
	_afficher_frame(_frame_actuelle)
	if _frame_actuelle >= _nb_frames - 1:
		_minuteur.stop()
		animation_terminee.emit()

func _arreter() -> void:
	if _minuteur != null:
		_minuteur.stop()
