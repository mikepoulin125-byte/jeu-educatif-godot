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

## Raffinements de l'ecran-titre (bordure, animations, son, ecran de chargement)

Quatre demandes supplementaires de Mike sur le menu principal :

1. **Bordure des boutons** : couleur exacte `#CC0000` (`Color(0.8, 0, 0,
   1)`), appliquee aux 3 etats (`normal`/`hover`/`pressed`) des 3
   boutons dans `scenes/MenuPrincipal.tscn`.
2. **Animation survol/clic** : `scripts/components/bouton_anime.gd`
   (`class_name BoutonAnime`, `extends Button`) — reutilisable sur
   n'importe quel bouton. Leger agrandissement (`scale` 1.0 -> 1.05) au
   survol, retrecissement (1.05 -> 0.94) a l'enfoncement, via
   `create_tween()` avec `TRANS_SINE`/`EASE_OUT` (pas de changement
   instantane). `pivot_offset` recalcule sur `resized` pour que la mise
   a l'echelle reste centree.
3. **Son de clic** : `scripts/autoload/audio_manager.gd` (autoload
   `AudioManager`), cherche `assets/audio/ui/clic_bouton.ogg` puis
   `.wav`. **Silencieux si absent** (choix delibere plutot qu'un son
   placeholder genere : plus simple, evite un bruit agacant en
   attendant le vrai son). `BoutonAnime` appelle
   `AudioManager.jouer_clic()` sur le signal `pressed`. Instructions
   dans `assets/audio/ui/LISEZ-MOI.txt`.
4. **Ecran de chargement factice** (`scenes/EcranChargement.tscn` +
   `scripts/ecran_chargement.gd`) entre le menu et
   `DialogueIntro.tscn`/`Hub.tscn` :
   - `menu_principal.gd` : au clic sur "Nouvelle partie"/"Continuer",
     desactive les 3 boutons, fixe `GameState.scene_suivante`, fait un
     fondu **au blanc** (`ColorRect` "FadeBlanc", tween sur `color:a`,
     0.45s) puis change de scene vers `EcranChargement.tscn`.
   - `EcranChargement` : `Timer` de 5.0s (`DUREE_CHARGEMENT`, meme si le
     "vrai" chargement est instantane), a la fin duquel il change de
     scene vers `GameState.scene_suivante`.
   - Icone centrale tournante : remplacable via
     `assets/ui/chargement/icone_chargement.png` (`ChargementAssetUtil`,
     meme principe que les autres assets remplacables), sinon
     placeholder (cercle gris + un petit repere colore decale du centre
     pour que la rotation soit visible). Rotation continue via
     `_process()`, 1 tour complet toutes les 2 secondes.
   - Texte "Chargement" + 3 points qui rebondissent en vague (decalage
     de phase de 100ms entre chaque point), egalement via `_process()`.
   - **Formules d'animation extraites dans
     `scripts/util/anim_math_util.gd`** (`class_name AnimMathUtil`,
     fonctions statiques pures `rotation_apres(temps)` et
     `decalage_point_chargement(temps, index)`) specifiquement pour
     pouvoir les tester sans instancier de scene ni faire tourner de
     moteur de rendu — reflexe a reprendre pour toute future logique
     d'animation non triviale.

### Nouveaux dossiers d'assets remplacables

- `assets/audio/ui/` (voir `LISEZ-MOI.txt`) : `clic_bouton.ogg` (ou
  `.wav`).
- `assets/ui/chargement/` (voir `LISEZ-MOI.txt`) : `icone_chargement.png`,
  200x200, transparent.

### Limite (re)documentee des smoke tests headless

`scripts/tests/smoke_test_raffinements_menu.gd` confirme que
`bouton.get_script()` **ne peut pas** etre verifie sous `--script`
quand ce script reference un autoload (ici `BoutonAnime` ->
`AudioManager`) : le script echoue a compiler dans ce mode special
(meme piege documente pour `DataManager`/`SaveManager`/`GameState`
depuis la Phase 2), et Godot n'attache alors *aucun* script au noeud
instancie plutot que d'attacher un script casse — donc
`get_script() == MonScript` echoue meme quand tout fonctionne
correctement en jeu reel. Verifie a la place par le boot headless reel
(`godot --headless --path <projet>`, sans `--script`), qui charge les
autoloads normalement et est reste a 0 erreur apres cet ajout.

## Transition radiale blanche (bords en premier / centre en premier)

Precision de Mike : le fondu au blanc ne devait pas etre un alpha
uniforme, mais un degrade radial anime — un effet vignette. Confirme
faisable avec un shader canvas_item avant implementation (une seule
formule, reutilisee pour les deux sens en inversant juste le point de
depart/arrivee) :

- `shaders/transition_radiale_blanc.gdshader` : `COLOR = vec4(1,1,1,alpha)`
  ou `alpha` vient d'un `smoothstep()` sur la distance normalisee au
  centre (`dist`, 0 au centre, 1 au coin le plus loin), compare a un
  seuil `1.0 - progression`. A `progression=0` -> rien de blanc ; a
  `progression=1` -> tout blanc ; entre les deux, le blanc gagne des
  bords vers le centre. **Le meme shader gere le sens inverse** (le
  blanc se retire du centre vers les bords) simplement en animant
  `progression` de 1.0 vers 0.0 au lieu de 0.0 vers 1.0 — pas besoin
  d'un deuxieme shader, la formule est symetrique.
- `scenes/components/TransitionRadiale.tscn` +
  `scripts/components/transition_radiale.gd` (`class_name
  TransitionRadiale`, `extends ColorRect`) : composant reutilisable.
  `definir_progression(valeur)` ecrit directement le parametre shader
  (fonctionne des l'instanciation, pas besoin d'attendre `_ready()` —
  meme reflexe que les autres composants de ce projet). `animer(depart,
  arrivee, duree) -> void` (fonction `await`-able) tween le parametre
  `shader_parameter/progression` du `ShaderMaterial`.
- **Les deux fondus demandes par Mike, exactement** ("applique-le aux
  deux fondus : celui du menu vers l'ecran de chargement, et celui de
  l'ecran de chargement vers le jeu") :
  1. `MenuPrincipal.tscn` (`%FadeBlanc`) : `animer(0.0, 1.0, 0.45)` au
     clic sur "Nouvelle partie"/"Continuer", **avant** de changer de
     scene vers `EcranChargement.tscn` (bords blancs en premier).
  2. `DialogueIntro.tscn` et `Hub.tscn` (`%VoileEntree` dans chacune) :
     `animer(1.0, 0.0, 0.45)` appele au tout debut de leur `_ready()`
     (centre revele en premier). Ces deux scenes sont les deux
     destinations possibles apres `EcranChargement` (Nouvelle partie ->
     DialogueIntro, Continuer -> Hub), donc les deux sont couvertes.
     `EcranChargement.tscn` lui-meme n'a pas besoin de logique de fondu
     supplementaire : son fond est deja blanc en permanence, donc la
     transition est deja visuellement continue avec la fin du fondu du
     menu (pas de "pop") ; c'est la scene de destination qui se revele
     depuis le blanc.
- **Effet de bord** : `Hub.tscn` est aussi atteinte directement depuis
  `SelectionStarter.tscn` (fin du choix du starter, hors ecran de
  chargement) ; le fondu d'entree du Hub joue donc aussi a ce moment-la.
  Considere comme un bonus esthetique inoffensif plutot qu'un probleme
  (le Hub se revele proprement dans les deux cas), pas de logique
  supplementaire ajoutee pour le distinguer.

### Verification effectuee (transition radiale)

- `godot --headless --path <projet> --import` : 0 erreur (shader
  compile correctement).
- Boot headless reel (autoloads charges) : 0 erreur stderr.
- `scripts/tests/smoke_test_transition_radiale.gd` : SUCCES — confirme
  entre autres qu'un `await voile.animer(...)` **fonctionne
  correctement en mode `--script`** (le tween s'exécute et la fonction
  reprend a la bonne valeur finale), contrairement au probleme de
  `_ready()` non-synchrone documente plus haut : la boucle de frame
  tourne bien pendant un `await`, seule la notification `_ready()`
  post-`add_child()` immediat pose probleme dans ce mode.
- `scripts/tests/smoke_test_raffinements_menu.gd` : mis a jour (l'ancien
  test lisait `fade_blanc.color.a`, qui n'a plus de sens depuis que
  `FadeBlanc` est une `TransitionRadiale` a shader — le shader ecrase
  `COLOR` entierement, la propriete `color` du noeud n'est plus lue).
  Lit maintenant `material.get_shader_parameter("progression")`.
- Verification visuelle reelle complete : jeu lance en fenetre, clic
  souris simule sur "Nouvelle partie", captures a t+0.22s (vignette
  radiale bien visible, bords blancs/coins envahis, centre encore
  visible), t+~1.1s (ecran de chargement affiche), et juste apres la
  fin du `Timer` de 5s (fondu radial inverse visible : `DialogueIntro`
  deja lisible au centre, residu blanc encore present dans les coins).

## Coherence visuelle Hub <-> menu (bordure/animation/son)

Une fois le style du menu principal valide par Mike (bordure `#CC0000`,
animation `BoutonAnime`, son de clic), les 8 badges de matiere et le
bouton Roster du hub ne l'avaient pas encore — rattrape ici pour que le
hub reprenne exactement le meme langage visuel :

- `scenes/components/CarteMatiere.tscn` : bordure `#CC0000` (5px) ajoutee
  aux 3 etats (`normal`/`hover`/`pressed`) du `StyleBoxFlat` du bouton
  circulaire, et script `BoutonAnime` attache a `%BoutonCercle` (en plus
  du script `carte_matiere.gd` sur la racine `VBoxContainer`, qui gere
  la configuration/l'icone — les deux scripts coexistent sans conflit,
  chacun connecte son propre listener au signal `pressed` du bouton).
- `scenes/Hub.tscn` : meme traitement sur `%BoutonRoster` (bordure
  `#CC0000` sur `StyleBoxFlat_pill_blanc`, script `BoutonAnime`).
- `scripts/tests/smoke_test_hub_style.gd` : verifie la bordure exacte
  sur `CarteMatiere` (3 etats) et `BoutonRoster`, plus la presence de
  `LabelXp`/`BoutonRoster`/`GrilleMatieres`.

### Verification effectuee (coherence visuelle hub/menu)

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (autoloads charges) : 0 erreur stderr.
- Suite complete des smoke tests (phase2, phase3, menu_principal,
  raffinements_menu, transition_radiale, hub_style) : tous SUCCES.
- Verification visuelle reelle : `run/main_scene` bascule temporairement
  sur `Hub.tscn`, jeu lance en fenetre. Capture confirmant la bordure
  rouge sur les 8 badges et le bouton Roster ; deuxieme capture avec le
  curseur survolant le premier badge confirmant l'agrandissement +
  changement de teinte de `BoutonAnime` (meme comportement que les
  boutons du menu). `run/main_scene` remis sur `Main.tscn` ensuite.

### Verification effectuee (raffinements)

- `godot --headless --path <projet> --import` : 0 erreur.
- Boot headless reel (autoloads charges, MenuPrincipal + BoutonAnime +
  AudioManager compilent) : 0 erreur stderr.
- `scripts/tests/smoke_test_raffinements_menu.gd` : SUCCES (formules de
  rotation/rebond, bordure #CC0000, silence d'`AudioManager`, structure
  de `EcranChargement.tscn`).
- Verification visuelle reelle complete : jeu lance en fenetre, clic
  souris simule sur "Nouvelle partie", captures a t+1.2s et t+2.0s
  confirmant la rotation du repere (visiblement deplace d'une capture a
  l'autre) et l'affichage du texte/points, puis capture a t+~7s (apres
  les 5s de `Timer`) confirmant l'arrivee sur `DialogueIntro.tscn`.
