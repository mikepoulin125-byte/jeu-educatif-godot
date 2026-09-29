extends Control
class_name BerryItem
## Icone de berry dans l'inventaire du Roster, draggable (glisser-deposer
## sur une creature). configurer() resout les noeuds enfants via %Nom a
## chaque appel (fonctionne des instantiate(), meme reflexe que les
## autres composants de ce projet).
##
## Animation "wobble" (Phase 8, demande de Mike) : une "secousse"
## (rotation + leger "bounce" d'echelle, aller-retour vers la position
## neutre), puis une pause SILENCIEUSE de 2 a 4 secondes, puis une
## nouvelle secousse — ainsi de suite en boucle. Chaque secousse choisit
## une nouvelle amplitude/duree au hasard, et un delai de depart
## aleatoire precede la toute premiere, pour que plusieurs berries a
## l'ecran ne soient jamais synchronisees. Utilise sur l'item
## d'inventaire lui-meme ET sur l'apercu de glisser-depose
## (_get_drag_data()).
##
## Survol (hover) de l'item d'inventaire : agrandissement + leger
## decalage vers le haut + z_index rehausse, feedback avant un
## glisser-deposer (distinct du hover de BoutonAnime, pense pour un
## bouton classique plutot qu'un item qu'on s'apprete a faire glisser).
## Le survol INTERROMPT proprement le wobble en cours (pas de conflit
## entre les deux animations sur scale/rotation) et le relance a la
## sortie du survol.

const AMPLITUDE_ROTATION_MIN_DEG := 4.0
const AMPLITUDE_ROTATION_MAX_DEG := 9.0
const AMPLITUDE_ECHELLE := 0.06
const DUREE_SECOUSSE_MIN := 0.35
const DUREE_SECOUSSE_MAX := 0.6
const PAUSE_MIN := 2.0
const PAUSE_MAX := 4.0

const ECHELLE_HOVER := Vector2(1.15, 1.15)
const DECALAGE_HOVER := Vector2(0.0, -10.0)
const DUREE_HOVER := 0.12

var index_inventaire: int = -1
var skin: int = 1

## Tween de wobble actif pour SELF uniquement (pas pour l'apercu de
## glisser-depose) — permet au survol de l'interrompre proprement.
var _tween_wobble_self: Tween
var _survole: bool = false
var _position_repos: Vector2 = Vector2.ZERO
var _position_capturee: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_survol_entre)
	mouse_exited.connect(_on_survol_sort)
	_demarrer_wobble(self)

func configurer(index: int, skin_valeur: int) -> void:
	index_inventaire = index
	skin = skin_valeur

	var texture_berry: TextureRect = %TextureBerry
	var placeholder: Panel = %PlaceholderBerry

	var texture := BerryAssetUtil.charger_texture(skin)
	if texture != null:
		texture_berry.texture = texture
		texture_berry.visible = true
		placeholder.visible = false
	else:
		texture_berry.visible = false
		placeholder.visible = true
		var style: StyleBoxFlat = placeholder.get_theme_stylebox("panel").duplicate()
		style.bg_color = BerryAssetUtil.couleur_placeholder(skin)
		placeholder.add_theme_stylebox_override("panel", style)

	tooltip_text = "Berry #%d" % skin

## Donnees transportees par le glisser-depose. Fonction pure separee de
## _get_drag_data() pour rester testable sans avoir besoin d'un Viewport
## reel actif (set_drag_preview() exige d'etre appelee pendant un vrai
## geste de glisser-depose, donc pas testable directement en headless).
func construire_charge_utile() -> Dictionary:
	return {"type": "berry", "index_inventaire": index_inventaire, "skin": skin}

func _get_drag_data(_at_position: Vector2) -> Variant:
	var texture_berry: TextureRect = %TextureBerry
	if texture_berry.visible and texture_berry.texture != null:
		var apercu := TextureRect.new()
		apercu.custom_minimum_size = Vector2(56, 56)
		apercu.size = Vector2(56, 56)
		apercu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		apercu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		apercu.texture = texture_berry.texture
		set_drag_preview(apercu)
		apercu.ready.connect(_demarrer_wobble.bind(apercu))
	else:
		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(56, 56)
		rect.size = Vector2(56, 56)
		rect.color = BerryAssetUtil.couleur_placeholder(skin)
		set_drag_preview(rect)
		rect.ready.connect(_demarrer_wobble.bind(rect))
	return construire_charge_utile()

## --- Wobble (secousse + pause, en boucle) ---

## Demarre le wobble sur n'importe quel Control (self, ou un apercu de
## glisser-depose cree a la volee) : delai de depart aleatoire puis
## premiere secousse. Fonctionne uniquement une fois le noeud reellement
## dans l'arbre (pivot_offset/get_tree() en dependent).
func _demarrer_wobble(cible: Control) -> void:
	if not cible.is_inside_tree():
		return
	cible.pivot_offset = cible.size / 2.0
	await cible.get_tree().create_timer(randf_range(0.0, DUREE_SECOUSSE_MAX)).timeout
	_cycle_wobble(cible)

## Une secousse (aller vers un angle/echelle aleatoires, puis retour a
## la position neutre) suivie d'une pause silencieuse de 2 a 4s, avant
## de s'enchainer sur la secousse suivante. Si "cible" est SELF et
## qu'un survol est en cours, ne fait rien : _on_survol_sort() relancera
## le cycle proprement a la sortie du survol.
func _cycle_wobble(cible: Control) -> void:
	if not is_instance_valid(cible) or not cible.is_inside_tree():
		return
	if cible == self and _survole:
		return

	var angle := deg_to_rad(randf_range(AMPLITUDE_ROTATION_MIN_DEG, AMPLITUDE_ROTATION_MAX_DEG))
	if randf() < 0.5:
		angle = -angle
	var echelle := 1.0 + randf_range(0.0, AMPLITUDE_ECHELLE)
	var duree := randf_range(DUREE_SECOUSSE_MIN, DUREE_SECOUSSE_MAX)
	var pause := randf_range(PAUSE_MIN, PAUSE_MAX)

	var tween := cible.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(cible, "rotation", angle, duree)
	tween.tween_property(cible, "scale", Vector2(echelle, echelle), duree)
	# IMPORTANT : `.chain()` (pas `set_parallel(false)` puis `set_parallel(true)`
	# a nouveau) pour ouvrir un VRAI nouveau groupe sequentiel ici — sans
	# ca, les deux groupes parallel(true) fusionnent silencieusement en un
	# seul (meme "rotation"/"scale"), et c'est la DERNIERE valeur ajoutee
	# qui "gagne" pour toute la duree : l'animation ne bougeait plus du
	# tout (bug trouve et corrige en testant ce changement).
	tween.chain()
	tween.tween_property(cible, "rotation", 0.0, duree)
	tween.tween_property(cible, "scale", Vector2.ONE, duree)
	tween.chain().tween_interval(pause)
	tween.chain().tween_callback(_cycle_wobble.bind(cible))

	if cible == self:
		_tween_wobble_self = tween

## --- Survol (hover) ---

func _on_survol_entre() -> void:
	_survole = true
	if not _position_capturee:
		_position_repos = position
		_position_capturee = true
	if _tween_wobble_self != null and _tween_wobble_self.is_valid():
		_tween_wobble_self.kill()

	z_index = 10
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", 0.0, DUREE_HOVER)
	tween.tween_property(self, "scale", ECHELLE_HOVER, DUREE_HOVER)
	tween.tween_property(self, "position", _position_repos + DECALAGE_HOVER, DUREE_HOVER)

func _on_survol_sort() -> void:
	_survole = false
	z_index = 0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, DUREE_HOVER)
	tween.tween_property(self, "position", _position_repos, DUREE_HOVER)
	# `.chain()` (pas set_parallel(false) seul) pour que le callback
	# attende vraiment la fin des deux tweeners ci-dessus — un simple
	# set_parallel(false) ne garantit pas d'attendre la fin du groupe
	# parallele precedent (verifie : le callback partait plus tot que
	# prevu sans .chain()).
	tween.chain().tween_callback(_cycle_wobble.bind(self))
