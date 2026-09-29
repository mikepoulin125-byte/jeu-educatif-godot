extends Node
## Gere les sons d'interface (clic de bouton, etc.) et les musiques de
## fond (titre/hub/debut de partie). Silencieux tant qu'aucun fichier
## n'est depose (voir assets/audio/ui/LISEZ-MOI.txt et
## assets/audio/musique/LISEZ-MOI.txt) — pas de placeholder sonore
## genere, pour eviter un bruit agacant en attendant le vrai son.
##
## Phase 8 : le son de clic est branche de facon CENTRALISEE sur TOUT
## bouton du jeu (menu, badges de matiere, niveaux, cartes de creature,
## boutons de reponse des tableaux, etc.) via `SceneTree.node_added` —
## chaque `BaseButton` qui entre dans l'arbre de scene se voit connecter
## automatiquement `button_down` vers `jouer_clic()`, qu'il s'agisse d'un
## bouton d'une scene (.tscn) ou cree dynamiquement par du code. Aucun
## script/signal a cabler a la main sur un bouton individuel pour qu'il
## ait le son.
##
## Deux consequences volontaires du choix de `button_down` plutot que
## `pressed` (qui n'emet qu'au RELACHEMENT du clic par defaut sur un
## Button Godot) :
## - Le son se declenche des l'appui, en parallele de l'animation
##   visuelle de BoutonAnime (qui demarre aussi sur `button_down`) —
##   plus reactif, corrige la latence percue signalee par Mike.
## - Un bouton DESACTIVE (`disabled = true`) n'emet jamais `button_down`
##   (comportement natif de Godot), donc pas de son sur un clic qui ne
##   declenche aucune action — mais si l'enfant appuie sur un bouton
##   puis fait glisser la souris hors du bouton avant de relacher (sans
##   jamais emettre `pressed`), le son aura quand meme joue a l'appui :
##   compromis assume pour la reactivite, ce cas est rare en pratique.

const CHEMINS_CLIC := [
	"res://assets/audio/ui/clic_bouton.ogg",
	"res://assets/audio/ui/clic_bouton.mp3",
	"res://assets/audio/ui/clic_bouton.wav",
]

const MUSIQUE_TITRE := "res://assets/audio/musique/titre.ogg"
const MUSIQUE_HUB := "res://assets/audio/musique/hub.ogg"
const MUSIQUE_DEBUT_PARTIE := "res://assets/audio/musique/debut_partie.ogg"

## Effets ponctuels (Phase 8, sequence de capture en fin de tableau reussi)
## : voir assets/audio/sfx/LISEZ-MOI.txt.
const CHEMINS_SON_CAPTURE := [
	"res://assets/audio/sfx/capture.ogg",
	"res://assets/audio/sfx/capture.mp3",
	"res://assets/audio/sfx/capture.wav",
]
const CHEMINS_SON_REUSSITE := [
	"res://assets/audio/sfx/reussite.ogg",
	"res://assets/audio/sfx/reussite.mp3",
	"res://assets/audio/sfx/reussite.wav",
]
const CHEMINS_SON_ATTAQUE := [
	"res://assets/audio/sfx/attaque.ogg",
	"res://assets/audio/sfx/attaque.mp3",
	"res://assets/audio/sfx/attaque.wav",
]

var _lecteur: AudioStreamPlayer
var _son_clic: AudioStream

var _lecteur_musique: AudioStreamPlayer
var _chemin_musique_actuelle: String = ""

func _ready() -> void:
	_lecteur = AudioStreamPlayer.new()
	add_child(_lecteur)
	_son_clic = _charger_premier_existant(CHEMINS_CLIC)

	_lecteur_musique = AudioStreamPlayer.new()
	add_child(_lecteur_musique)

	var arbre := get_tree()
	if arbre != null:
		arbre.node_added.connect(_sur_noeud_ajoute)

func _sur_noeud_ajoute(noeud: Node) -> void:
	if noeud is BaseButton:
		noeud.button_down.connect(jouer_clic)

func jouer_clic() -> void:
	if _son_clic == null:
		return
	_lecteur.stream = _son_clic
	_lecteur.play()

## Joue une musique de fond en boucle. Ne fait rien si cette meme piste
## joue deja (evite un redemarrage audible en changeant d'ecran, ex.
## DialogueIntro -> SelectionStarter avec la meme musique de debut de
## partie). Reste silencieux si le fichier n'est pas encore depose.
func jouer_musique(chemin: String) -> void:
	if chemin == _chemin_musique_actuelle and _lecteur_musique.playing:
		return
	if not FileAccess.file_exists(chemin):
		_lecteur_musique.stop()
		_chemin_musique_actuelle = ""
		return
	var stream := load(chemin) as AudioStream
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_lecteur_musique.stream = stream
	_lecteur_musique.play()
	_chemin_musique_actuelle = chemin

func arreter_musique() -> void:
	_lecteur_musique.stop()
	_chemin_musique_actuelle = ""

## Joue un effet sonore PONCTUEL (pas de boucle, pas partage avec
## _lecteur qui sert au clic) via un AudioStreamPlayer jetable, libere
## automatiquement une fois le son termine. Reste silencieux tant
## qu'aucun des chemins fournis n'existe (meme principe que le son de
## clic : pas de placeholder sonore).
func jouer_effet_ponctuel(chemins: Array) -> void:
	var son := _charger_premier_existant(chemins)
	if son == null:
		return
	var lecteur := AudioStreamPlayer.new()
	add_child(lecteur)
	lecteur.stream = son
	lecteur.finished.connect(lecteur.queue_free)
	lecteur.play()

func jouer_son_capture() -> void:
	jouer_effet_ponctuel(CHEMINS_SON_CAPTURE)

func jouer_son_reussite() -> void:
	jouer_effet_ponctuel(CHEMINS_SON_REUSSITE)

func jouer_son_attaque() -> void:
	jouer_effet_ponctuel(CHEMINS_SON_ATTAQUE)

func _charger_premier_existant(chemins: Array) -> AudioStream:
	for chemin in chemins:
		if FileAccess.file_exists(chemin):
			return load(chemin) as AudioStream
	return null
