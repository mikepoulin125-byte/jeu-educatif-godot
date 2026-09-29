extends Node
## Autoload centralisant TOUTES les transitions entre scenes/ecrans du
## jeu : fondu au blanc (TransitionRadiale) -> courte attente -> fondu
## depuis le blanc sur la nouvelle scene. Remplace get_tree().change_scene_to_file()
## partout dans le jeu, pour que chaque changement d'ecran suive
## exactement la meme sequence sans dupliquer la logique dans chaque script.
##
## Un seul voile partage (CanvasLayer cree ici, donc persiste a travers
## change_scene_to_file puisqu'un autoload ne fait pas partie de la scene
## remplacee) plutot qu'une instance de TransitionRadiale par scene.

const TransitionRadialeScene := preload("res://scenes/components/TransitionRadiale.tscn")

const DUREE_FONDU := 0.35
const ATTENTE_ECRAN_BLANC := 0.03

var _voile: TransitionRadiale
var _en_transition: bool = false

func _ready() -> void:
	var couche := CanvasLayer.new()
	couche.layer = 100
	add_child(couche)
	_voile = TransitionRadialeScene.instantiate()
	couche.add_child(_voile)
	_voile.definir_progression(0.0)

## A appeler a la place de get_tree().change_scene_to_file() pour toute
## navigation entre ecrans. Ignore les appels recus pendant qu'une
## transition est deja en cours (protege contre un double-clic sur un
## bouton de navigation).
func changer_scene(chemin: String, duree_fondu: float = DUREE_FONDU, attente: float = ATTENTE_ECRAN_BLANC) -> void:
	if _en_transition:
		return
	_en_transition = true

	await _voile.animer(0.0, 1.0, duree_fondu)
	await get_tree().create_timer(attente).timeout
	get_tree().change_scene_to_file(chemin)

	# change_scene_to_file() remplace la scene en differe : attendre deux
	# frames garantit que _ready() de la nouvelle scene a deja tourne
	# avant de reveler l'ecran.
	await get_tree().process_frame
	await get_tree().process_frame
	await _voile.animer(1.0, 0.0, duree_fondu)

	_en_transition = false
