extends Control
## Widget de reponse pour la matiere "pair_impair".
## Contrat commun a tous les widgets de scripts/tableau/ :
## configurer(question: Dictionary, contexte: Dictionary) -> void
## signal reponse_donnee(correcte: bool)
##
## 2 formats de question coexistent (migration progressive niveau par
## niveau, demande de Mike) :
## - Ancien (niveaux pas encore migres) : { "nombre": int, "reponse": "pair"|"impair" }
##   -> choix binaire Pair/Impair sur UN nombre.
## - Nouveau (niveau 1, puis progressivement les suivants) :
##   { "nombres": [8 entiers], "cible": "pair"|"impair" } -> grille de 8
##   nombres, le joueur clique les 4 nombres de la parite "cible" (defaut
##   "pair" si absent, pour compatibilite avec le niveau 1). Correct
##   seulement si les 4 cliques correspondent tous a la cible.
## - Niveau 3 : { "creature_id": "cN", "quantite": int (1-9) } -> affiche
##   "quantite" images de la MEME creature (1 a 9), le joueur clique
##   Pair/Impair (boutons reutilises) pour dire si la quantite affichee
##   est paire ou impaire. Reponse deduite de "quantite" (pas de champ
##   "reponse" separe, une seule source de verite).
## - Niveau 4 : { "min": int, "max": int, "cible": "pair"|"impair" } ->
##   2 boites de saisie (1 caractere chacune). Correct si les 2 valeurs
##   saisies sont : de la bonne parite, comprises entre min et max
##   (inclus), et DIFFERENTES l'une de l'autre.
## - Niveau 6 : { "suite": [3 entiers donnes], "suivants": [2 ou 3 entiers
##   attendus] } -> affiche la suite donnee, le joueur ecrit les N
##   prochains termes (une boite par terme, 2 chiffres max). Correct
##   seulement si TOUTES les valeurs saisies correspondent exactement,
##   dans l'ordre, aux valeurs de "suivants".
## - Niveau 9 : { "a": int, "b": int, "op": "+"|"-" } -> affiche
##   l'operation (ex. "32 + 10"), le joueur clique Pair/Impair (boutons
##   reutilises) selon la parite du RESULTAT (deduit, pas saisi).
## - Niveau 10 : { "a": int, "op": "+"|"-", "cible": "pair"|"impair" } ->
##   "a OP ___ = ?", le joueur ECRIT le nombre manquant pour que le
##   resultat soit de la parite "cible". Le resultat s'affiche en direct
##   pendant la saisie (pas seulement a la validation). Correct si la
##   saisie est un entier valide ET (a OP saisie) a la bonne parite.
##
## Resout %Nom a la demande (pas de cache @onready) : ce widget est
## instancie puis configure() immediatement par ecran_tableau.gd, avant
## que _ready() ne soit forcement passe (meme piege documente pour
## CarteMatiere/CarteCreature en Phase 3).

signal reponse_donnee(correcte: bool)

var _reponse_attendue: String = ""
var _boutons_connectes: bool = false

var _mode_grille: bool = false
var _mode_creatures: bool = false
var _mode_saisie: bool = false
var _mode_suite: bool = false
var _nb_clics: int = 0
var _tous_corrects: bool = true
var _cible: String = "pair"
var _min_saisie: int = 0
var _max_saisie: int = 9
var _suivants: Array = []
var _mode_creation: bool = false
var _a_creation: int = 0
var _op_creation: String = "+"

func _ready() -> void:
	_connecter_boutons()

func configurer(question: Dictionary, _contexte: Dictionary) -> void:
	_connecter_boutons()
	_mode_grille = question.has("nombres")
	_mode_creatures = question.has("creature_id")
	_mode_saisie = question.has("min") and question.has("max")
	_mode_suite = question.has("suite")
	_mode_creation = question.has("a") and question.has("op") and question.has("cible") and not question.has("b")

	var label_nombre: Label = %LabelNombre
	var hbox_boutons: HBoxContainer = %HBoxBoutons
	var label_consigne: Label = %LabelConsigne
	var grille: GridContainer = %GrilleNombres
	var grille_creatures: GridContainer = %GrilleCreatures
	var zone_saisie: VBoxContainer = %ZoneSaisie
	var zone_suite: VBoxContainer = %ZoneSuite
	var zone_creation: VBoxContainer = %ZoneCreation

	var mode_special := _mode_grille or _mode_creatures or _mode_saisie or _mode_suite or _mode_creation
	# LabelNombre reste VISIBLE (mais texte vide) en mode creatures pour
	# que VBox garde le meme espace reserve et que HBoxBoutons ne remonte
	# pas prendre sa place — sinon les boutons se retrouvent derriere
	# GrilleCreatures (recollee plus haut faute d'espace reserve par un
	# enfant invisible) et deviennent non cliquables.
	label_nombre.visible = not mode_special or _mode_creatures
	if _mode_creatures:
		label_nombre.text = ""
	hbox_boutons.visible = not _mode_grille and not _mode_saisie and not _mode_suite and not _mode_creation
	label_consigne.visible = _mode_grille or _mode_saisie
	grille.visible = _mode_grille
	grille_creatures.visible = _mode_creatures
	zone_saisie.visible = _mode_saisie
	zone_suite.visible = _mode_suite
	zone_creation.visible = _mode_creation

	if _mode_grille:
		_nb_clics = 0
		_tous_corrects = true
		_cible = String(question.get("cible", "pair"))
		label_consigne.text = "Clique sur les 4 nombres %s" % ("PAIRS" if _cible == "pair" else "IMPAIRS")
		var nombres: Array = question.get("nombres", [])
		for i in range(8):
			var bouton: Button = grille.get_node("Bouton%d" % i)
			bouton.text = str(int(nombres[i])) if i < nombres.size() else "0"
			bouton.disabled = false
	elif _mode_creatures:
		var creature_id := String(question.get("creature_id", ""))
		var quantite: int = clampi(int(question.get("quantite", 1)), 1, 9)
		_reponse_attendue = "pair" if quantite % 2 == 0 else "impair"
		var texture := SpriteUtil.charger_texture(creature_id)
		var nb_frames := SpriteUtil.compter_frames(texture)
		for i in range(9):
			var case: TextureRectAnime = grille_creatures.get_node("Creature%d" % i)
			case.visible = i < quantite
			if i < quantite:
				case.configurer_animation(texture, nb_frames)
		var bouton_pair: Button = %BoutonPair
		var bouton_impair: Button = %BoutonImpair
		bouton_pair.disabled = false
		bouton_impair.disabled = false
	elif _mode_saisie:
		_min_saisie = int(question.get("min", 0))
		_max_saisie = int(question.get("max", 9))
		_cible = String(question.get("cible", "pair"))
		label_consigne.text = "Ecris 2 nombres %s entre %d et %d" % ["pairs" if _cible == "pair" else "impairs", _min_saisie, _max_saisie]
		var input0: LineEdit = %Input0
		var input1: LineEdit = %Input1
		input0.text = ""
		input1.text = ""
		input0.editable = true
		input1.editable = true
		var bouton_valider: Button = %BoutonValider
		bouton_valider.disabled = true
	elif _mode_suite:
		var suite: Array = question.get("suite", [])
		_suivants = question.get("suivants", [])
		var label_suite: Label = zone_suite.get_node("LabelSuiteAffichee")
		var textes_suite := []
		for n in suite:
			textes_suite.append(str(int(n)))
		label_suite.text = ", ".join(textes_suite) + ", ..."
		for i in range(3):
			var input: LineEdit = zone_suite.get_node("HBoxSuiteInputs/Suite%d" % i)
			input.visible = i < _suivants.size()
			input.text = ""
			input.editable = true
		var bouton_valider_suite: Button = %BoutonValiderSuite
		bouton_valider_suite.disabled = true
	elif _mode_creation:
		_a_creation = int(question.get("a", 0))
		_op_creation = String(question.get("op", "+"))
		_cible = String(question.get("cible", "pair"))
		var label_consigne_creation: Label = zone_creation.get_node("LabelConsigneCreation")
		label_consigne_creation.text = "Cree un resultat %s" % ("PAIR" if _cible == "pair" else "IMPAIR")
		var label_operande_a: Label = zone_creation.get_node("HBoxExpression/LabelOperandeA")
		var label_operateur: Label = zone_creation.get_node("HBoxExpression/LabelOperateur")
		var input_creation: LineEdit = zone_creation.get_node("HBoxExpression/InputCreation")
		var label_resultat_creation: Label = zone_creation.get_node("HBoxExpression/LabelResultatCreation")
		label_operande_a.text = str(_a_creation)
		label_operateur.text = _op_creation
		input_creation.text = ""
		input_creation.editable = true
		label_resultat_creation.text = "?"
		var bouton_confirmer_creation: Button = %BoutonConfirmerCreation
		bouton_confirmer_creation.disabled = true
	elif question.has("a") and question.has("b") and question.has("op"):
		# Niveau 9 : affiche une operation (ex. "32 + 10"), le joueur
		# clique Pair/Impair selon la parite du RESULTAT (reponse
		# deduite, pas de champ "reponse" separe).
		var a := int(question.get("a", 0))
		var b := int(question.get("b", 0))
		var op := String(question.get("op", "+"))
		var resultat := a + b if op == "+" else a - b
		label_nombre.text = "%d %s %d" % [a, op, b]
		_reponse_attendue = "pair" if resultat % 2 == 0 else "impair"
		var bouton_pair2: Button = %BoutonPair
		var bouton_impair2: Button = %BoutonImpair
		bouton_pair2.disabled = false
		bouton_impair2.disabled = false
	else:
		label_nombre.text = str(int(question.get("nombre", 0)))
		_reponse_attendue = String(question.get("reponse", ""))
		var bouton_pair: Button = %BoutonPair
		var bouton_impair: Button = %BoutonImpair
		bouton_pair.disabled = false
		bouton_impair.disabled = false

func _connecter_boutons() -> void:
	if _boutons_connectes:
		return
	var bouton_pair: Button = %BoutonPair
	var bouton_impair: Button = %BoutonImpair
	bouton_pair.pressed.connect(func(): _repondre("pair"))
	bouton_impair.pressed.connect(func(): _repondre("impair"))
	var grille: GridContainer = %GrilleNombres
	for i in range(8):
		var bouton: Button = grille.get_node("Bouton%d" % i)
		bouton.pressed.connect(_sur_clic_grille.bind(bouton))
	var bouton_valider: Button = %BoutonValider
	bouton_valider.pressed.connect(_sur_validation_saisie)
	var input0: LineEdit = %Input0
	var input1: LineEdit = %Input1
	input0.text_changed.connect(func(_t): _sur_texte_saisie_change())
	input1.text_changed.connect(func(_t): _sur_texte_saisie_change())
	var bouton_valider_suite: Button = %BoutonValiderSuite
	bouton_valider_suite.pressed.connect(_sur_validation_suite)
	var zone_suite: VBoxContainer = %ZoneSuite
	for i in range(3):
		var input_suite: LineEdit = zone_suite.get_node("HBoxSuiteInputs/Suite%d" % i)
		input_suite.text_changed.connect(func(_t): _sur_texte_suite_change())
	var input_creation: LineEdit = %InputCreation
	input_creation.text_changed.connect(_sur_texte_creation_change)
	var bouton_confirmer_creation: Button = %BoutonConfirmerCreation
	bouton_confirmer_creation.pressed.connect(_sur_validation_creation)
	_boutons_connectes = true

func _repondre(choix: String) -> void:
	var bouton_pair: Button = %BoutonPair
	var bouton_impair: Button = %BoutonImpair
	bouton_pair.disabled = true
	bouton_impair.disabled = true
	reponse_donnee.emit(choix == _reponse_attendue)

## N'active "Valider" que lorsque les 2 cases sont remplies (evite un
## clic premature sur une case encore vide, qui donnait une fausse
## mauvaise reponse — bug rapporte par Mike).
func _sur_texte_saisie_change() -> void:
	if not _mode_saisie:
		return
	var input0: LineEdit = %Input0
	var input1: LineEdit = %Input1
	var bouton_valider: Button = %BoutonValider
	bouton_valider.disabled = input0.text.is_empty() or input1.text.is_empty()

## Meme garde-fou que _sur_texte_saisie_change() pour la suite (niveau 6,
## 2 ou 3 cases visibles selon la question).
func _sur_texte_suite_change() -> void:
	if not _mode_suite:
		return
	var zone_suite: VBoxContainer = %ZoneSuite
	var bouton_valider_suite: Button = %BoutonValiderSuite
	var toutes_remplies := true
	for i in range(_suivants.size()):
		var input: LineEdit = zone_suite.get_node("HBoxSuiteInputs/Suite%d" % i)
		if input.text.is_empty():
			toutes_remplies = false
	bouton_valider_suite.disabled = not toutes_remplies

func _sur_validation_saisie() -> void:
	if not _mode_saisie:
		return
	var input0: LineEdit = %Input0
	var input1: LineEdit = %Input1
	var bouton_valider: Button = %BoutonValider
	bouton_valider.disabled = true
	input0.editable = false
	input1.editable = false

	var texte0 := input0.text.strip_edges()
	var texte1 := input1.text.strip_edges()
	var correct := texte0.is_valid_int() and texte1.is_valid_int()
	if correct:
		var valeur0 := int(texte0)
		var valeur1 := int(texte1)
		var cible_paire := _cible == "pair"
		correct = valeur0 != valeur1 \
			and valeur0 >= _min_saisie and valeur0 <= _max_saisie \
			and valeur1 >= _min_saisie and valeur1 <= _max_saisie \
			and (valeur0 % 2 == 0) == cible_paire \
			and (valeur1 % 2 == 0) == cible_paire
	reponse_donnee.emit(correct)

func _sur_validation_suite() -> void:
	if not _mode_suite:
		return
	var zone_suite: VBoxContainer = %ZoneSuite
	var bouton_valider_suite: Button = %BoutonValiderSuite
	bouton_valider_suite.disabled = true

	var correct := true
	for i in range(_suivants.size()):
		var input: LineEdit = zone_suite.get_node("HBoxSuiteInputs/Suite%d" % i)
		input.editable = false
		var texte := input.text.strip_edges()
		if not texte.is_valid_int() or int(texte) != int(_suivants[i]):
			correct = false
	reponse_donnee.emit(correct)

## Recalcule et affiche le resultat en direct pendant la saisie (demande
## de Mike) : "?" tant que le texte n'est pas un entier valide.
func _sur_texte_creation_change(nouveau_texte: String) -> void:
	if not _mode_creation:
		return
	var label_resultat_creation: Label = %LabelResultatCreation
	var texte := nouveau_texte.strip_edges()
	var bouton_confirmer_creation: Button = %BoutonConfirmerCreation
	if texte.is_valid_int():
		var x := int(texte)
		var resultat := _a_creation + x if _op_creation == "+" else _a_creation - x
		label_resultat_creation.text = str(resultat)
		bouton_confirmer_creation.disabled = false
	else:
		label_resultat_creation.text = "?"
		bouton_confirmer_creation.disabled = true

func _sur_validation_creation() -> void:
	if not _mode_creation:
		return
	var input_creation: LineEdit = %InputCreation
	var bouton_confirmer_creation: Button = %BoutonConfirmerCreation
	bouton_confirmer_creation.disabled = true
	input_creation.editable = false

	var texte := input_creation.text.strip_edges()
	var correct := false
	if texte.is_valid_int():
		var x := int(texte)
		var resultat := _a_creation + x if _op_creation == "+" else _a_creation - x
		correct = (resultat % 2 == 0) == (_cible == "pair")
	reponse_donnee.emit(correct)

func _sur_clic_grille(bouton: Button) -> void:
	if not _mode_grille or bouton.disabled:
		return
	bouton.disabled = true
	var nombre := int(bouton.text)
	var est_pair := nombre % 2 == 0
	if (_cible == "pair") != est_pair:
		_tous_corrects = false
	_nb_clics += 1
	if _nb_clics >= 4:
		var grille: GridContainer = %GrilleNombres
		for i in range(8):
			var b: Button = grille.get_node("Bouton%d" % i)
			b.disabled = true
		reponse_donnee.emit(_tous_corrects)
