class_name BoutonAnime
extends Button
## Bouton avec transition fluide au survol (leger agrandissement) et a
## l'enfoncement (retrecissement), plus un son de clic (AudioManager,
## silencieux tant qu'aucun son n'est depose). Reutilisable sur n'importe
## quel Button en lui assignant simplement ce script.

const ECHELLE_SURVOL := Vector2(1.05, 1.05)
const ECHELLE_ENFONCE := Vector2(0.94, 0.94)
const ECHELLE_NORMALE := Vector2(1.0, 1.0)
const DUREE_SURVOL := 0.12
const DUREE_ENFONCE := 0.08

var _survole: bool = false
var _tween: Tween

func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	mouse_entered.connect(_on_survol_entre)
	mouse_exited.connect(_on_survol_sort)
	button_down.connect(_on_enfonce)
	button_up.connect(_on_relache)
	pressed.connect(_on_presse)

func _on_survol_entre() -> void:
	_survole = true
	_animer_vers(ECHELLE_SURVOL, DUREE_SURVOL)

func _on_survol_sort() -> void:
	_survole = false
	_animer_vers(ECHELLE_NORMALE, DUREE_SURVOL)

func _on_enfonce() -> void:
	_animer_vers(ECHELLE_ENFONCE, DUREE_ENFONCE)

func _on_relache() -> void:
	_animer_vers(ECHELLE_SURVOL if _survole else ECHELLE_NORMALE, DUREE_ENFONCE)

func _on_presse() -> void:
	AudioManager.jouer_clic()

func _animer_vers(echelle_cible: Vector2, duree: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", echelle_cible, duree)
