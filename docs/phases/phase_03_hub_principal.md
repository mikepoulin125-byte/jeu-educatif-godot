# Phase 3 - Hub principal

## Fichiers crees

- `scripts/util/ui_icon_util.gd` (`class_name UiIconUtil`) : meme
  principe que `SpriteUtil` (Phase 2), mais pour `assets/ui/*.png`.
  Resout un id d'icone vers son fichier s'il existe, sinon `null`.
- `scenes/components/CarteMatiere.tscn` + `scripts/components/carte_matiere.gd` :
  badge/bouton reutilisable pour une matiere (icone reelle ou
  placeholder + nom + description). La racine est elle-meme un
  `Button` (texte vide), toute la carte est cliquable. Emet
  `choisie(matiere_id)`.
- `scenes/Hub.tscn` + `scripts/hub.gd` : le hub principal (section 6 de
  la spec). Affiche `SaveManager.get_xp_total()` en haut-gauche, un
  bouton Roster permanent en haut-droite, et une grille 4x8 (colonnes)
  de `CarteMatiere` generee dynamiquement depuis `DataManager.matieres`
  (donc directement pilotee par `data/matieres.json`, aucune matiere en
  dur).
- `scenes/SelectionNiveau.tscn` + `scripts/selection_niveau_placeholder.gd` :
  **placeholder Phase 5**. Confirme juste que le clic sur un badge
  fonctionne (affiche le nom de la matiere choisie via
  `GameState.matiere_courante_id`) et permet de revenir au hub.
- `scenes/Roster.tscn` + `scripts/roster_placeholder.gd` : **placeholder
  Phase 4**. Confirme que le bouton Roster du hub fonctionne, permet de
  revenir au hub.
- `scripts/tests/smoke_test_phase3.gd` : verifie que les 8 matieres se
  chargent avec les bons ids, que chaque `CarteMatiere` s'applique
  correctement (egalite stricte du nom affiche, pas juste "non vide"),
  et que `SaveManager.add_xp()` met a jour le total correctement.

## Navigation mise a jour

- `menu_principal.gd` ("Continuer") et `selection_starter.gd` (apres
  choix du starter) menent maintenant vers `Hub.tscn` (au lieu du
  placeholder `DebugEtatSauvegarde.tscn` de la Phase 1/2, qui reste
  dans le repo comme outil de debug mais n'est plus reference par le
  flux normal).
- Hub -> clic sur une matiere -> `SelectionNiveau.tscn` (placeholder).
- Hub -> bouton Roster -> `Roster.tscn` (placeholder).
- Les transitions fade in/out prevues par la spec (section 8) sont
  **volontairement differees a la Phase 8** ("Polish et integration
  finale"), qui est explicitement dediee aux transitions dans le
  decoupage en 8 phases (section 12 de la spec). Pour l'instant, les
  changements de scene sont instantanes.

## Bug important trouve et corrige (affecte aussi la Phase 2)

**`@onready var x = %NodeName` ne se peuple qu'au moment ou `_ready()`
se declenche, et `_ready()` n'est PAS forcement synchrone apres
`add_child()`.** Dans un script `SceneTree` lance via
`godot --headless --script ...` (utilise par tous les smoke tests de ce
projet), il n'y a pas de boucle de frame avant `quit()` : un noeud
ajoute dynamiquement (`instantiate()` + `add_child()` + configuration
immediate) peut ne jamais recevoir son `_ready()` avant la fin du
script. Le test Phase 3 (avec verification stricte du texte, contrairement
au test Phase 2 initial qui verifiait seulement "non vide" — un faux
positif silencieux) a mis ce bug en evidence : `CarteMatiere.configurer()`
mettait les donnees "en attente" pour `_ready()`, mais `_ready()` n'arrivait
jamais dans ce contexte, donc le texte restait au placeholder par defaut du
`.tscn` ("Nom"/"Description").

**Correctif applique a `CarteCreature` et `CarteMatiere`** : abandon du
cache `@onready` + mecanisme "en attente" pour resoudre les noeuds
enfants (`%NodeName`) directement dans `configurer()`/`_appliquer()`,
a chaque appel. La resolution `%NodeName` fonctionne des
`instantiate()` (elle depend de `owner`, deja assigne a
l'instanciation, pas de `_ready()`). Le bouton "pressed" est connecte
de facon idempotente (flag `_pressed_connecte`) a la fois depuis
`_ready()` (cas normal du jeu) et depuis `configurer()` (au cas ou
configurer() est appele avant que le noeud n'entre dans l'arbre).

**Reflexe a appliquer pour tout futur composant reutilisable** :
preferer la resolution `%NodeName` a la demande plutot que le cache
`@onready`, des qu'un composant peut etre configure immediatement apres
`instantiate()` (avant ou juste apres `add_child()`). Le smoke test
Phase 2 a aussi ete durci (egalite stricte du nom, plus "non vide") pour
eviter de refaire ce genre de faux positif a l'avenir.

**Autre piege decouvert : `assert()` dans un script headless peut
bloquer indefiniment.** Un `assert()` qui echoue declenche une pause du
debugger de script GDScript ; sans debugger attache (cas normal d'un
`godot --headless --script ...` lance depuis un terminal), le processus
reste bloque au lieu de planter proprement. Les deux smoke tests
utilisent maintenant une fonction `_verifier(condition, message)` qui
imprime l'echec et appelle `quit(1)` explicitement — **ne plus jamais
utiliser `assert()` dans un script de test headless de ce projet.**

## Verification effectuee

- `godot --headless --path <projet> --import` : 0 erreur.
- Execution headless du boot (Main -> MenuPrincipal) : 0 erreur stderr.
- `scripts/tests/smoke_test_phase2.gd` (durci) : SUCCES.
- `scripts/tests/smoke_test_phase3.gd` : SUCCES.
- Verification visuelle reelle : `run/main_scene` bascule temporairement
  sur `Hub.tscn`, jeu lance en fenetre (pas headless), capture d'ecran
  native (Win32 `CopyFromScreen` via PowerShell, pas besoin d'outil
  d'automatisation) pour confirmer le rendu du style (voir section
  suivante), puis `run/main_scene` remis sur `Main.tscn`.

## Style visuel (mise a jour post-Phase 3, a la demande de Mike)

Mike a fourni une image de reference (hub d'un jeu de capture de
creatures) decrivant : fond a bandes diagonales bicolores + triangle
clair en coin, boutons ronds blancs avec icone coloree simple au centre
et libelle blanc en dessous, disposition en grille alignee a gauche,
barre d'info sombre semi-transparente en bas. **Contrainte stricte
respectee : aucun asset/logo/icone specifique reproduit — seul le
langage visuel generique (grille de boutons ronds, fond a bandes,
palette vive, flat design) a ete reutilise, avec une palette et des
icones entierement originales.**

- `shaders/fond_bandes_diagonales.gdshader` : shader canvas_item
  parametrable (uniforms `couleur_fond`, `couleur_bande`,
  `couleur_triangle`, `largeur_bande`, `position_bande`,
  `taille_triangle`) qui dessine le fond a bandes diagonales + triangle
  clair. Applique via `ShaderMaterial` sur le `ColorRect` "Fond" de
  `Hub.tscn`. Facilement modifiable (changer les uniforms dans
  l'inspecteur Godot) sans toucher au code.
- `data/matieres.json` : ajout des champs `couleur` (hex) et `symbole`
  (1-2 caracteres) par matiere, utilises pour le placeholder colore
  de l'icone tant que `assets/ui/icone_matiere_NN.png` n'existe pas.
  Purement des donnees, aucun graphisme en dur dans le code.
- `scenes/components/CarteMatiere.tscn` refondu : racine
  `VBoxContainer`, bouton circulaire blanc (`StyleBoxFlat` avec
  `corner_radius` = moitie de la taille, states normal/hover/pressed),
  icone reelle ou pastille coloree + symbole au centre, libelle blanc
  (avec contour sombre pour la lisibilite sur fond colore) en dessous
  du cercle — pas cliquable lui-meme, seul le cercle l'est.
  `scripts/components/carte_matiere.gd` mis a jour en consequence
  (lit `couleur`/`symbole`, duplique le `StyleBoxFlat` de la pastille
  pour ne pas modifier la resource partagee entre instances).
- `Hub.tscn` : XP et titre en blanc avec contour sombre (lisibilite sur
  fond colore), bouton Roster restyle en pilule blanche (meme famille
  visuelle que les cartes de matiere), ajout d'une barre d'info sombre
  semi-transparente en bas d'ecran (texte generique "Clique sur une
  matiere pour commencer" — pas de fonctionnalite de badge "NEW"
  ajoutee, l'idee est notee pour une phase future si Mike la demande).

### Piege technique evite

`add_theme_stylebox_override("panel", style)` sur le `Panel` de la
pastille placeholder **duplique** le `StyleBoxFlat` partage
(`style.duplicate()`) avant de changer `bg_color` — sinon, changer la
couleur d'une carte changerait la couleur de TOUTES les cartes qui
partagent la meme resource `SubResource` de base (piege classique des
ressources partagees en Godot).

## Style visuel de l'ecran-titre (mise a jour post-Phase 3 ter)

Mike a fourni une deuxieme image de reference, cette fois un
**ecran-titre reel de Pokemon Violet** (logo protege par copyright/
marque). **Contrainte legale stricte respectee** : seuls la
disposition generale (zone logo en coin, zone d'action ailleurs) et le
principe de police (bold, ronde, lisible) ont ete repris — aucun texte,
logo, police stylisee ou couleur exacte de la reference n'a ete
reproduit. Le titre ("Aventure Mathematique"), toutes les couleurs et
tous les textes sont originaux.

- **Mecanisme d'assets remplacables generalise** (meme principe que
  `SpriteUtil`/`UiIconUtil`) : `scripts/util/menu_asset_util.gd`
  (`class_name MenuAssetUtil`) resout `assets/ui/menu/fond_menu.png`
  (fond plein ecran, 1920x1080) et `assets/ui/menu/logo_menu.png`
  (logo/titre, 560x280, transparent, affiche en haut-droite). Tant
  qu'un fichier n'existe pas, `null` est retourne et un placeholder
  s'affiche a la meme position/taille. Instructions completes pour
  Mike dans `assets/ui/menu/LISEZ-MOI.txt` (noms de fichiers exacts,
  format, dimensions, position).
- `scenes/MenuPrincipal.tscn` refondu : `TextureFond`/`PlaceholderFond`
  (fond, ColorRect brun chaleureux tant que `fond_menu.png` n'existe
  pas), `ZoneLogo` en haut-droite (`TextureLogo`/`PlaceholderLogo`,
  ce dernier etant un cadre `StyleBoxFlat` avec le titre du jeu),
  `ZoneBoutons` en bas-droite : panneau semi-transparent contenant les
  3 vrais boutons (Nouvelle partie / Continuer / Quitter), cliquables
  a la souris (ce sont des `Button` standards Godot, donc deja
  cliquables/focusables nativement — pas de logique custom necessaire
  au-dela du style).
- Style des boutons "fortement inspire" (langage visuel generique
  uniquement) : pilules blanches arrondies (`corner_radius` = moitie
  de la hauteur), bordure coloree epaisse, texte bold colore, 4 etats
  (`normal`/`hover`/`pressed`/`disabled`) via des `StyleBoxFlat`
  distincts. "Nouvelle partie"/"Continuer" en accent bleu (style
  "action principale"), "Quitter" en accent gris neutre (style
  "action secondaire"), "Continuer" grise quand
  `SaveManager.has_save()` est faux — meme logique qu'avant, juste
  restylee.
- `scripts/tests/smoke_test_menu_principal.gd` : verifie que
  `MenuAssetUtil` retourne `null` tant qu'aucun fichier n'est depose,
  que les placeholders sont actifs par defaut dans le `.tscn`, et que
  les 3 boutons existent. **Limite documentee** : ce test ne peut pas
  executer `_ready()` de `menu_principal.gd` (il reference l'autoload
  `SaveManager` par son nom global, qui ne compile pas sous
  `--script`, meme piege que Phase 2/3) — le comportement runtime
  complet (chargement des assets, etat desactive de "Continuer") est
  couvert par le boot headless reel (`godot --headless --path
  <projet>`, sans `--script`) qui charge les autoloads normalement.

### Verification effectuee (ecran-titre)

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (Main -> MenuPrincipal, autoloads charges) : 0
  erreur stderr.
- `scripts/tests/smoke_test_menu_principal.gd` : SUCCES.
- Verification visuelle reelle : jeu lance en fenetre, capture d'ecran
  native, **puis clic souris simule sur "Nouvelle partie"** (pas
  seulement clavier) confirmant la transition vers `DialogueIntro.tscn`.
