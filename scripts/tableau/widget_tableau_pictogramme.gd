extends Control
## Widget "tableau_pictogramme" : un graphique a bandes (contexte.graphique,
## partage par les 10 questions du niveau) + une question numerique sur
## ce graphique a chaque fois. Barres dessinees avec de simples
## ColorRect (pas d'assets requis). Resout %Nom a la demande (voir
## widget_pair_impair.gd pour le pourquoi).
##
## Phase 8 (badge "Tableau et pictogrammes", vrai "pictogramme" plutot
## qu'un nom de categorie en texte) : chaque barre du graphique et
## chaque question peuvent identifier une categorie par un sprite de
## creature (barre["id_creature"] / question["id_creature"], id 1-151
## pige au hasard cote contenu) au lieu d'un texte ("categorie"/
## "texte"). Les deux formats coexistent : les tableaux pas encore
## refaits gardent categorie/texte tels quels (retombe dessus si
## id_creature absent), en attendant d'etre refaits un par un (meme
## principe que les autres badges de ce projet).

signal reponse_donnee(correcte: bool)

const HAUTEUR_MAX_BARRE := 180.0
const LARGEUR_BARRE := 70.0
const TAILLE_ICONE_QUESTION := 40

var _reponse_attendue: int = 0
var _graphique_affiche: bool = false
var _connecte: bool = false

func _ready() -> void:
	_connecter()

func configurer(question: Dictionary, contexte: Dictionary) -> void:
	_connecter()
	var graphique: Dictionary = contexte.get("graphique", {})
	if not _graphique_affiche:
		_construire_graphique(graphique)
		_graphique_affiche = true

	_construire_texte_question(question)
	_reponse_attendue = int(question.get("reponse", 0))
	var champ_reponse: LineEdit = %ChampReponse
	var bouton_valider: Button = %BoutonValider
	champ_reponse.text = ""
	champ_reponse.editable = true
	bouton_valider.disabled = false

func _connecter() -> void:
	if _connecte:
		return
	var champ_reponse: LineEdit = %ChampReponse
	var bouton_valider: Button = %BoutonValider
	bouton_valider.pressed.connect(_valider)
	champ_reponse.text_submitted.connect(func(_t): _valider())
	_connecte = true

func _construire_graphique(graphique: Dictionary) -> void:
	var label_titre: Label = %LabelTitre
	label_titre.text = String(graphique.get("titre", ""))
	var barres: Array = graphique.get("barres", [])
	var valeur_max := 1
	for barre in barres:
		valeur_max = max(valeur_max, int(barre.get("valeur", 0)))

	var zone_barres: HBoxContainer = %ZoneBarres
	for enfant in zone_barres.get_children():
		enfant.queue_free()

	for barre in barres:
		var valeur: int = int(barre.get("valeur", 0))
		var hauteur: float = (float(valeur) / float(valeur_max)) * HAUTEUR_MAX_BARRE

		var colonne := VBoxContainer.new()
		colonne.custom_minimum_size = Vector2(LARGEUR_BARRE, 0)
		colonne.alignment = BoxContainer.ALIGNMENT_END

		var label_valeur := Label.new()
		label_valeur.text = str(valeur)
		label_valeur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(LARGEUR_BARRE, hauteur)
		rect.color = Color(0.23, 0.51, 0.96, 1)

		colonne.add_child(label_valeur)
		colonne.add_child(rect)
		zone_barres.add_child(colonne)
		# "colonne" est ajoutee a l'arbre AVANT de construire l'identifiant
		# de la barre : si c'est un sprite anime, TextureRectAnime cree un
		# Timer et l'appelle start() des configurer_animation() - un Timer
		# demarre hors de l'arbre ne tourne pas tant que son noeud n'y
		# entre pas (piege documente dans CLAUDE.md), donc on construit
		# ici en ajoutant chaque noeud a son parent (deja dans l'arbre)
		# avant d'aller plus loin, plutot que de tout assembler hors-arbre
		# et attacher le tout d'un coup a la fin.
		_ajouter_identifiant_barre(colonne, barre)

## Sous chaque barre : le sprite (anime) de la creature si
## barre["id_creature"] est fourni, sinon l'ancien texte de categorie
## (barre["categorie"]) - voir le docstring en tete de fichier. "colonne"
## doit deja etre dans l'arbre (voir l'appel dans _construire_graphique()).
func _ajouter_identifiant_barre(colonne: VBoxContainer, barre: Dictionary) -> void:
	if not barre.has("id_creature"):
		var label_nom := Label.new()
		label_nom.text = String(barre.get("categorie", ""))
		label_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_nom.autowrap_mode = TextServer.AUTOWRAP_WORD
		colonne.add_child(label_nom)
		return

	var zone := Control.new()
	zone.custom_minimum_size = Vector2(LARGEUR_BARRE, LARGEUR_BARRE)
	colonne.add_child(zone)

	var texture_sprite := TextureRectAnime.new()
	texture_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	zone.add_child(texture_sprite)

	var placeholder := ColorRect.new()
	placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	placeholder.color = Color(0.6, 0.6, 0.6, 1.0)
	zone.add_child(placeholder)

	var sprite_id := "c%d" % int(barre["id_creature"])
	var texture := SpriteUtil.charger_texture(sprite_id)
	if texture != null:
		texture_sprite.configurer_animation(texture, SpriteUtil.compter_frames(texture))
		texture_sprite.visible = true
		placeholder.visible = false
	else:
		texture_sprite.visible = false
		placeholder.visible = true

## Question : "Combien de [sprite] y a-t-il ?" si question["id_creature"]
## est fourni (sprite affiche EN LIGNE dans le texte, figee sur sa
## premiere frame - une image inline ne peut pas s'animer), sinon
## l'ancien texte litteral (question["texte"]).
func _construire_texte_question(question: Dictionary) -> void:
	var rtl: RichTextLabel = %LabelTexte
	rtl.clear()
	rtl.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	if question.has("id_creature"):
		rtl.add_text("Combien de ")
		var sprite_id := "c%d" % int(question["id_creature"])
		var texture := SpriteUtil.charger_texture(sprite_id)
		if texture != null:
			rtl.add_image(_premiere_frame(texture), TAILLE_ICONE_QUESTION, TAILLE_ICONE_QUESTION)
		else:
			rtl.add_text("[%s]" % sprite_id)
		rtl.add_text(" y a-t-il ?")
	else:
		rtl.add_text(String(question.get("texte", "")))
	rtl.pop()

## Les sprites de creatures sont des planches de plusieurs frames cote a
## cote (voir SpriteUtil) - une image inline de RichTextLabel ne peut
## pas jouer d'animation, donc on n'en extrait que la 1ere.
func _premiere_frame(texture: Texture2D) -> Texture2D:
	var nb_frames := SpriteUtil.compter_frames(texture)
	if nb_frames <= 1:
		return texture
	var taille_frame := texture.get_height()
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, taille_frame, taille_frame)
	return atlas

func _valider() -> void:
	var champ_reponse: LineEdit = %ChampReponse
	if not champ_reponse.text.is_valid_int():
		return
	var valeur := int(champ_reponse.text)
	champ_reponse.editable = false
	var bouton_valider: Button = %BoutonValider
	bouton_valider.disabled = true
	reponse_donnee.emit(valeur == _reponse_attendue)
