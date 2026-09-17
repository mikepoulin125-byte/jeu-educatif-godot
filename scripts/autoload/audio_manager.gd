extends Node
## Gere les sons d'interface (clic de bouton, etc.). Silencieux tant
## qu'aucun fichier n'est depose (voir assets/audio/ui/LISEZ-MOI.txt) —
## pas de son placeholder genere, pour eviter un bruit agacant en
## attendant le vrai son.

const CHEMINS_CLIC := [
	"res://assets/audio/ui/clic_bouton.ogg",
	"res://assets/audio/ui/clic_bouton.wav",
]

var _lecteur: AudioStreamPlayer
var _son_clic: AudioStream

func _ready() -> void:
	_lecteur = AudioStreamPlayer.new()
	add_child(_lecteur)
	_son_clic = _charger_premier_existant(CHEMINS_CLIC)

func jouer_clic() -> void:
	if _son_clic == null:
		return
	_lecteur.stream = _son_clic
	_lecteur.play()

func _charger_premier_existant(chemins: Array) -> AudioStream:
	for chemin in chemins:
		if FileAccess.file_exists(chemin):
			return load(chemin) as AudioStream
	return null
