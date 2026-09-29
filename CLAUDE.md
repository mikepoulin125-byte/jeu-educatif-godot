# Jeu educatif de mathematiques (2e annee, Quebec)

Godot 4.6, GDScript. Jeu de type "capture de creatures" avec mecaniques
educatives de mathematiques (curriculum 2e annee Quebec). Aucun asset, nom
ou texte Pokemon dans le code : creatures generiques (`c1.gif` a
`c151.gif`, GIF anime depuis la Phase 8 — voir
`assets/creatures/LISEZ-MOI.txt`), tout le contenu thematique (noms,
niveaux, table de types) vient de `data/*.json`, fournis par Mike.

**Vigilance IP/legal** : Mike fournit parfois par erreur un vrai asset de
marque (ex. le logo Pokemon trouve dans `assets/ui/menu/logo_menu.png`
en Phase 8) au lieu d'un asset original — un tel fichier ne doit jamais
etre integre/commite, le signaler a Mike et le supprimer. Ne plus ouvrir
les fichiers PNG/image de Mike avec l'outil de lecture (`Read`) sauf
demande explicite — verifier un asset (dimensions, existence) par des
moyens non visuels (taille de fichier, script headless) plutot que de
l'ouvrir.

Spec complete d'origine : voir le premier message de la session qui a
demarre ce projet (2026-09-17) si besoin de retrouver un detail non
couvert ci-dessous ou dans les archives de phase.

Godot 4.6.3 est installe sur la machine
(`%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe`, installe via winget).
Toujours verifier une phase avec
`godot --headless --path <projet_racine> --import` (0 erreur attendue)
avant de la considerer terminee. Le dossier `scripts/tests/` contient des
scripts de smoke test headless (`godot --headless --script res://scripts/tests/<nom>.gd`) —
en ajouter un par phase qui touche a de la logique non triviale, et le
relancer si le code concerne est modifie plus tard.

## Etat actuel

**Phases 1 a 7 (+ 4 bis) terminees et verifiees** (voir archives
ci-dessous) — toutes les mecaniques de jeu de la spec d'origine sont
maintenant fonctionnelles de bout en bout (menu -> hub -> tableaux ->
rencontre/capture -> roster). **Phase 8 (polish) en cours**, pas encore
archivee (toujours des demandes en cours de route) — voir plus bas.

**Deja fait en Phase 8** :
- Transitions fade in/out generalisees a TOUT le jeu via l'autoload
  `SceneTransition` (`scripts/autoload/scene_transition.gd`,
  `changer_scene(chemin)` a la place de
  `get_tree().change_scene_to_file()` partout) — un seul voile
  `TransitionRadiale` partage plutot qu'une instance par scene.
- Musiques de fond (`AudioManager.jouer_musique()`, boucle
  automatique) : titre, hub, debut de partie — voir
  `assets/audio/musique/LISEZ-MOI.txt`.
- Raccourci Bureau (`lancer_jeu.bat`) : reimporte les assets AVANT de
  lancer le jeu compile (sinon un fichier fraichement depose n'a pas
  encore de `.import`, `load()` echoue silencieusement) et convertit
  les GIF (`scripts/tools/convertir_gifs.ps1`) — voir plus bas.
- Sprites de creatures migres de PNG statique a GIF anime (voir
  `assets/creatures/LISEZ-MOI.txt` pour la convention complete) : GIF
  converti automatiquement en planche PNG (frames carrees cote a cote)
  par `convertir_gifs.ps1`, `SpriteUtil.compter_frames()` deduit le
  nombre de frames depuis les dimensions de la planche,
  `TextureRectAnime` (script attache directement aux noeuds
  TextureRect existants, `class_name TextureRectAnime`) anime le
  cycle des frames. Tous les affichages de creatures du jeu (Roster,
  EcranTableau joueur/sauvage, CarteCreature, CarteCreatureRoster,
  Hub) utilisent desormais ce composant.
- Hub : 2 zones de decor flanquant la grille de matieres (`ZoneGauche`/
  `ZoneDroite`, centrees verticalement dans leur moitie d'ecran) —
  gauche = contenu pas encore determine par Mike (`HubAssetUtil`),
  droite = creature principale du joueur, animee.
- Contenu des 40 fichiers de niveaux les plus repetitifs regenere
  (`fractions`, `tableau_pictogramme`, `possible_impossible`,
  `plan_cartesien` — les 4 autres matieres avaient deja une bonne
  variete, non touchees). Regenere via un script GDScript jetable (non
  versionne, meme esprit que le script d'auteur original de la Phase
  6) avec RNG seedee par matiere+niveau ; `possible_impossible` reste
  coherent avec `data/types.json` (la table de types y=bat), verifie
  par un script de validation jetable separe (parse + coherence
  interne des 80 fichiers) avant suppression des deux scripts.
- Son de clic centralise sur TOUT `BaseButton` du jeu, plutot que
  seulement les boutons scriptes `BoutonAnime` : `AudioManager`
  connecte automatiquement `button_down -> jouer_clic()` via
  `SceneTree.node_added` des qu'un bouton entre dans l'arbre (aucun
  cablage par scene). Utilise `button_down` (declenche a l'appui) et
  non `pressed` (ne se declenche qu'au relachement par defaut sur un
  Button Godot) pour une reactivite percue immediate — `BoutonAnime`
  ne gere plus lui-meme le son (retire, redondant avec le hook
  centralise).
- SelectionNiveau : grille 5x2 (deja le cas, `columns=5` sur
  `GrilleNiveaux`) + chemin de terre procedural (`CheminNiveaux`,
  `_draw()` pur GDScript, dessine des tirets courbes entre les CENTRES
  reels des 10 cartes apres leur layout — pas d'asset externe, purement
  decoratif, `mouse_filter = IGNORE`) + un 11e niveau **"Examen"**
  place SOUS la grille (`ZoneExamen`, hors du `GridContainer` pour
  eviter une rangee de 5+5+1 mal centree). L'examen pose 10 questions
  parmi celles RATEES par le joueur a travers les 10 niveaux normaux de
  la matiere (nouveau : `SaveManager.ajouter_question_ratee()` /
  `get_questions_ratees()`, alimente depuis `ecran_tableau.gd` a chaque
  mauvaise reponse, y compris dans l'examen lui-meme). Seuil de
  reussite 70% comme les niveaux normaux, mais calcule en POURCENTAGE
  (`RATIO_REUSSITE`/`RATIO_BONUS` dans `ecran_tableau.gd`, remplacent les
  anciennes constantes fixes `SEUIL_REUSSITE`/`SEUIL_BONUS` qui
  assumaient toujours 10 questions) car l'examen peut avoir MOINS de 10
  questions ; sur un niveau normal (toujours 10 questions), le resultat
  est identique a avant (7/10 et 8/10).
  - **Decision de conception** (pas precisee par la demande d'origine) :
    si le pool de questions ratees ne suffit pas pour atteindre 10,
    l'examen se complete avec des questions deja vues (n'importe quel
    niveau deja tente de la matiere) plutot que d'etre bloque ; si
    meme ca ne suffit pas, l'examen se joue simplement avec MOINS de
    10 questions (jamais bloque une fois debloque). Logique pure et
    testable isolement dans `ExamenUtil.construire_questions()`.
  - **Deblocage de l'examen** : des que le niveau 1 de la matiere a ete
    tente au moins une fois (reussi ou non) — garantit un pool d'au
    moins 10 questions "deja vues" pour le completer au besoin.
  - Icone du coin superieur droit de la carte Examen : UNE icone PAR
    MATIERE (confirme par Mike), fichier `exam_<matiere_id>_icon.png`
    dans `assets/ui/examen/`, `<matiere_id>` = le meme "id" que
    `data/matieres.json`/`data/niveaux/*.json` (`ExamenAssetUtil`,
    voir `assets/ui/examen/LISEZ-MOI.txt` pour la liste des 8 noms
    exacts attendus).
  - Verification visuelle du chemin (courbes/tirets) et de l'icone NON
    faite : verifications headless uniquement pour cette tache (demande
    explicite de Mike), donc seule la MECANIQUE est garantie correcte
    (`scripts/tests/smoke_test_examen.gd`), pas le rendu a l'ecran —
    a valider par Mike via son raccourci.
- Icone Examen : `exam_<matiere_id>_icon.png` sert AUSSI d'icone du
  badge Hub (`carte_matiere.gd` charge `ExamenAssetUtil.charger_icone()`
  directement, plus l'ancien champ `matieres.json.icone` qui n'est plus
  lu) — un seul fichier pour les deux endroits, reduite a 76x76 dans le
  coin de la carte Examen (-30% demande par Mike, etait 108x108).
- CarteMatiere (badges du Hub) : fond brun/beige pale (etait blanc),
  contour DOUBLE — BLANC epais (6px, bordure du bouton lui-meme ;
  etait rouge #CC0000, change sur demande explicite de Mike) + anneau
  noir fin (3px, `AnneauNoir`, Panel separe insere juste a l'interieur
  du bouton). Libelle sous le badge (`LabelNom`) cache (texte toujours
  rempli en interne, juste invisible).
- `ScrollMatieres` recentre sur l'ECRAN ENTIER (marges symetriques
  80/-80) plutot que sur l'espace restant entre `ZoneGauche`/`ZoneDroite`
  (qui avait pousse la grille visiblement vers la droite une fois
  `ZoneGauche` agrandie) — la grille (770px de large) tient largement
  dans l'espace entre les deux zones sans les chevaucher, donc pas
  besoin de calculer une marge asymetrique.
- Berries (`BerryItem`) : animation "wobble" = UNE secousse
  (rotation + leger "bounce" d'echelle, aller-retour vers la position
  neutre) puis une PAUSE silencieuse de 2 a 4s avant de recommencer
  (pas une boucle continue sans pause — ajuste sur demande de Mike),
  delai de depart aleatoire avant la toute premiere secousse (berries
  jamais synchronisees entre elles). Sur l'item d'inventaire ET
  l'apercu de glisser-depose. Survol (hover) de l'item d'inventaire :
  agrandissement + leger decalage vers le haut + z_index rehausse,
  interrompt proprement le wobble en cours et le relance a la sortie.
  Convention des skins de berries INCHANGEE :
  `assets/ui/berries/berryN.png` (N=1 a 10), voir
  `assets/ui/berries/LISEZ-MOI.txt`.
- EcranTableau : apres CHAQUE bonne reponse (pas seulement en fin de
  tableau), deux anims (`ecran_tableau.gd`) :
  - XP "machine a sous" (`_animer_xp_gagne()`) : le compteur defile de
    l'ancienne a la nouvelle valeur (`tween_method` + lerp arrondi,
    jamais un saut instantane) avec un petit "pop" d'echelle sur
    `LabelXp`.
  - Berry qui "pop" pres du message de feedback puis vole jusqu'a une
    NOUVELLE barre de berries sous le XP (`BarreBerries`/
    `IconeBerryBarre`/`LabelCompteBerries`, meme mecanisme
    placeholder-si-absent que partout ailleurs) avant de disparaitre en
    incrementant le compteur (`_animer_gain_berry()`). Icone FIXE
    (skin 7, `SKIN_BERRY_BARRE`) pour identifier visuellement la barre
    — independant du skin reellement gagne (tirage aleatoire inchange
    cote `SaveManager.ajouter_berry()`).
  - Les deux reutilisent le pattern `.chain()` verifie ci-dessous (pas
    de `set_parallel(false)`/`true` en alternance).
  - **Non verifiable en headless** : `ecran_tableau.gd` reference les
    autoloads (SaveManager/DataManager/GameState/SceneTransition) donc
    ne compile pas sous `--script` (limite documentee depuis la Phase 2)
    — seule la STRUCTURE des nouveaux noeuds est testee
    (`smoke_test_phase7.gd`), pas le comportement des deux fonctions
    d'anim elles-memes. A valider visuellement par Mike.
- DialogueIntro ("Nouvelle partie") : fond d'ecran remplacable ajoute
  (`TextureFond`/`PlaceholderFond`, `DialogueIntroAssetUtil`, meme
  mecanisme que partout ailleurs) — voir
  `assets/ui/dialogue_intro/LISEZ-MOI.txt` (`fond.png`, 1920x1080).
- CarteCreature (choix du starter, 3 premieres creatures) : sprite
  reduit de 50% (chaque dimension lineaire, pas juste l'aire) — le
  `TextureSprite`/`PlaceholderSprite` occupe desormais le centre
  50%x50% de `SpriteZone` (anchors 0.25-0.75) au lieu de la remplir
  entierement ; la carte et sa zone reservee gardent la meme taille,
  seul le rendu visuel de la creature retrecit.
- CarteMatiere (badges du Hub) : contour exterieur repasse a BLANC
  (etait rouge, cf. plus haut) sur demande explicite de Mike — l'anneau
  noir interieur (`AnneauNoir`) reste inchange.
- **Bug corrige : bouton Quitter inactif pendant un tableau.**
  `ZoneReponse` (Control plein ecran, ajoutee APRES `BoutonQuitter`
  dans l'arbre donc prioritaire pour le hit-testing des clics) avait le
  `mouse_filter` par defaut (STOP), donc absorbait TOUS les clics sur
  toute sa surface — y compris par-dessus le bouton Quitter, positionne
  ailleurs dans l'arbre mais visuellement "derriere" elle. Fixe avec
  `mouse_filter = 2` (IGNORE) sur `ZoneReponse` : les zones vides
  laissent maintenant passer les clics, ses enfants (les boutons du
  widget de reponse) continuent de fonctionner normalement.
- EcranTableau : fond d'ecran remplacable, UN PAR MATIERE (pas un fond
  unique) — `TextureFond`/`Fond` (renomme depuis l'ancien `Fond` seul),
  `TableauAssetUtil.charger_fond(matiere_id)`, voir
  `assets/ui/tableau/LISEZ-MOI.txt` (`fond_<id>.png`, 8 fichiers
  possibles, un par matiere de `data/matieres.json`).
- **Bug corrige : XP "machine a sous" affichait des gains massifs ou
  des retraits.** Cause : `tween_method(fn.bind(a, b), ...)` — `Callable.bind()`
  AJOUTE ses arguments APRES ceux fournis par l'appelant (pas avant).
  `tween_method` appelait donc `_afficher_xp_intermediaire(t, xp_avant, xp_apres)`
  alors que la fonction attendait `(xp_avant, xp_apres, t)` : "t"
  (0.0-1.0) se retrouvait interprete comme un XP, et `xp_apres` comme
  le "t" de `lerpf()` (souvent tres > 1, parfois negatif selon les
  valeurs) — d'ou des sauts incoherents. **Reflexe a garder : ne jamais
  utiliser `tween_method(...).bind(...)` avec des arguments dont l'ORDRE
  compte sans avoir verifie ce comportement.** Corrige en reecrivant
  l'anim SANS `tween_method`/`bind()` : une boucle qui incremente le
  compteur affiche d'UNE UNITE a la fois (`await create_timer(pas).timeout`),
  avec un jeton (`_jeton_anim_xp`) qui invalide proprement une anim en
  cours si une nouvelle bonne reponse arrive avant la fin — l'affichage
  ne peut plus jamais reculer ni sauter, et le rendu "chiffres qui
  defilent vite un par un" correspond mieux a l'effet "machine a sous"
  demande par Mike qu'un lerp lisse.
- Roster : **bug corrige** — la barre XP de CHAQUE creature affichait
  `min(xp_total_du_joueur, cout)`, donc le MEME nombre (ex. 200 XP)
  apparaissait sur la barre de toutes les creatures (donnant
  l'impression fausse qu'elles progressaient toutes pareil). Nouveau
  champ persiste par creature `xp_investi_stade_actuel` (distinct de
  `xp_investi`, qui reste le cumul historique inchange) +
  `SaveManager.ajouter_xp_creature(id, montant, stage_max)` /
  `get_progression_stade_creature(id)`. Le bouton "Attribuer XP" du
  Roster attribue maintenant par BONDS DE 10 (`INCREMENT_XP_MANUEL`,
  un clic = +10 vers le palier de LA creature selectionnee, retire du
  portefeuille du joueur) au lieu de deduire tout le cout d'un coup —
  l'evolution se declenche automatiquement des que le palier est
  atteint. L'ancien `faire_evoluer_creature()` (tout le cout d'un coup)
  reste dans `SaveManager`, inchange, juste plus appele par le Roster.
- SelectionStarter (choix des 3 premieres creatures) : police Rubik
  (`Rubik-Bold.ttf`, deja utilisee ailleurs dans le projet) appliquee
  au titre et au nom de chaque creature (`CarteCreature.LabelNom`) —
  Mike a demande "police cubik", interprete comme Rubik (police deja
  integree, aucune autre "Cubik"/"Cubic" trouvee dans le projet) ; a
  confirmer/corriger si ce n'etait pas ca.
- Hub : `ZoneGauche` reduite de 50%% supplementaires (440x680 ->
  220x340) et `ZoneDroite` (creature principale) reduite de 60%%
  (220x340 -> 88x136) ET repositionnee juste a cote de `ZoneGauche`
  (avant : loin a droite de l'ecran) — ancrage passe de droite a
  gauche (`anchor_left/right = 0` au lieu de `1`). Titre change de
  "Choisis une matiere" a "Choisis un badge".
- EcranTableau : creature du JOUEUR affichee DE DOS pendant un tableau
  (Mike a depose les 151 creatures en 4 variantes : face `cN`,
  face+glow `cN_glow`, dos `cbN`, dos+glow `cbN_glow` — voir
  `assets/creatures/LISEZ-MOI.txt`). Nouveau
  `SpriteUtil.id_dos(sprite_id)` (`"c1"` -> `"cb1"`) +
  `charger_texture_dos_avec_glow()` qui retombe automatiquement sur la
  version de face si la version de dos n'existe pas encore pour cette
  creature (repli en cascade, jamais de placeholder vide le temps que
  Mike termine de deposer les 4 x 151 fichiers). La creature SAUVAGE
  (en face) est inchangee, toujours `SpriteUtil.charger_texture()`.
- EcranTableau : animation "impact" a chaque bonne reponse — la
  creature du joueur (`ZoneJoueur`, maintenant `unique_name_in_owner`)
  charge horizontalement vers la creature sauvage (`DISTANCE_LUNGE`)
  puis revient (recul, `Tween.TRANS_BACK`), et au moment de l'impact
  (`_declencher_impact()`) la creature sauvage (`ZoneSauvage`, aussi
  nommee) recule brievement ET flashe en blanc via un nouveau shader
  (`shaders/flash_blanc.gdshader`, `uniform float intensite` melange
  RGB -> blanc en preservant l'alpha, applique comme `ShaderMaterial`
  sur `TextureSauvage`, anime 0 -> 1 -> 0 par tween). Timings courts
  (`DUREE_LUNGE=0.12`, `DUREE_RECOIL=0.22`, `DUREE_FLASH=0.18`) pour
  tenir largement dans `DUREE_FEEDBACK=1.1s`, tourne en parallele des
  anims XP/berry (noeuds differents, aucun conflit). Ecrit avec
  `tween.chain()` (pas de `set_parallel()` en alternance) et sans
  `tween_method()+bind()` — conforme aux deux pieges Tween documentes
  plus bas.
  - **Non verifiable en headless** (meme limite que les autres anims de
    `ecran_tableau.gd`, le script racine ne compile pas sous
    `--script` a cause des references aux autoloads) : seule la
    STRUCTURE est testee (`smoke_test_phase7.gd` — noms uniques de
    `%ZoneJoueur`/`%ZoneSauvage`, presence du `ShaderMaterial` avec le
    parametre `intensite` a 0.0 par defaut). Le rendu/timing reel est
    a valider par Mike via son raccourci.
- EcranTableau : fond d'ecran repasse a UN SEUL fond PARTAGE par tous
  les tableaux (Mike a change d'avis — c'etait un fond par matiere,
  voir plus haut) — `TableauAssetUtil.charger_fond()` n'a plus de
  parametre `matiere_id`, cherche juste `assets/ui/tableau/fond.<ext>`
  en essayant `jpeg`/`jpg`/`png` dans cet ordre (Mike a depose un
  `.jpeg`). Voir `assets/ui/tableau/LISEZ-MOI.txt` (mis a jour).
  - Positionnement de `ZoneJoueur`/`ZoneSauvage` (et leurs labels de
    nom) : Mike a fourni `assets/ui/tableau/fondzones.jpeg` (copie de
    son fond avec un point ROUGE = centre voulu pour la creature du
    joueur, point BLEU = centre voulu pour la creature sauvage, sur
    les 2 clairières rondes vert foncé du decor). Centres mesures par
    script (PowerShell + `System.Drawing`, centroide des pixels
    rouges/bleus) plutot qu'a l'oeil : rouge ≈ (27.1%%, 76.2%%) de
    l'image, bleu ≈ (69.6%%, 47.3%%). Les deux zones sont maintenant
    ancrees PAR POINT (`anchor_left = anchor_right`, `anchor_top =
    anchor_bottom`, ces fractions exactes) plutot que par un offset
    fixe en pixels depuis un bord — necessaire car le fond remplit
    tout l'ecran et les fractions doivent rester justes peu importe la
    resolution. `fondzones.jpeg` est un fichier de reperage fourni par
    Mike (pas utilise en jeu, ne correspond pas au motif `fond.<ext>`
    lu par `TableauAssetUtil`, donc jamais charge par erreur comme
    fond).
  - **Exception au reflexe "ne jamais ouvrir les PNG/images de Mike"** :
    Mike a explicitement autorise a regarder `fondzones.jpeg` pour ce
    repérage precis (image de decor/reperes, pas un asset de creature)
    — reste une exception ponctuelle, pas un changement de regle
    generale (toujours ne pas ouvrir les sprites de creatures etc.).
- EcranTableau : sequence de CAPTURE a la derniere reponse d'un tableau
  REUSSI (>=70%%, demande de Mike) — remplace l'anim d'impact habituelle
  (`_animer_impact_combat()`) par `_jouer_sequence_capture()` :
  1. `catch.gif` (nouveau fichier special, PAS une creature —
     `assets/creatures/catch.gif`, voir `assets/creatures/LISEZ-MOI.txt`
     section 4, meme pipeline GIF->PNG que les creatures) est "lance"
     depuis le coin bas-gauche de l'ecran vers la creature sauvage, en
     legere courbe vers le haut (2 segments de tween vers un point
     "sommet" plus haut que le depart/l'arrivee, pas une vraie parabole
     — evite `tween_method()+bind()`, piege deja documente plus bas).
  2. Le gif est joue UNE SEULE FOIS puis se fige sur sa derniere frame
     (nouvelle methode generique `TextureRectAnime.configurer_animation_unique()`,
     par opposition a `configurer_animation()` qui boucle toujours —
     emet le signal `animation_terminee` une fois figee, utile pour
     d'autres effets ponctuels futurs).
  3. Vers les 3/4 de la duree du gif (calculee depuis `nb_frames/fps`),
     la creature sauvage retrecit et est "aspiree" vers le centre du
     gif (`_absorber_creature_sauvage()`, tween parallele position+scale
     vers zero, `pivot_offset` au centre) puis disparait.
  4. L'ecran de resultats habituel s'affiche ensuite
     (`_terminer_tableau()`, appele directement par la sequence — PAS
     par `timer_avance`, contrairement au flux normal).
  - 2 nouveaux sons ponctuels (`AudioManager.jouer_effet_ponctuel()`,
    generique, `AudioStreamPlayer` jetable) : `jouer_son_capture()` au
    lancer du gif, `jouer_son_reussite()` juste avant l'ecran de
    resultats — voir `assets/audio/sfx/LISEZ-MOI.txt` (`capture.*`,
    `reussite.*`, silencieux tant qu'absents, meme principe que le son
    de clic).
  - Un 3e son ponctuel, `jouer_son_attaque()`, ajoute ensuite pour
    l'anim d'impact NORMALE (bonne reponse qui n'est pas la derniere
    d'un tableau reussi) — voir `assets/audio/sfx/attaque.*` dans le
    meme LISEZ-MOI.
  - **Retiming demande par Mike** : `jouer_son_attaque()` se declenche
    desormais IMMEDIATEMENT au clic sur la bonne reponse (deplace de
    `_declencher_impact()`, qui jouait au moment de l'impact visuel,
    vers `_on_reponse_donnee()`), et l'anim (charge/impact/recul) ne
    demarre que `DELAI_AVANT_ATTAQUE = 1.0`s APRES le debut du son (pas
    apres sa fin) via `_lancer_impact_combat_differe()`. `timer_avance`
    (avance vers la question suivante) attend en consequence
    `DUREE_FEEDBACK_AVEC_ATTAQUE` (delai + duree totale de l'anim +
    marge) au lieu du `DUREE_FEEDBACK` habituel de 1.1s sur CE cas
    precis (`timer_avance.start(DUREE_FEEDBACK_AVEC_ATTAQUE)`, `Timer.start(t)`
    accepte une duree ponctuelle sans toucher `wait_time`) — sinon la
    question suivante s'afficherait alors que l'anim d'attaque joue
    encore.
  - Nouveaux noeuds `ZoneCatch`/`TextureCatch`/`PlaceholderCatch` dans
    `EcranTableau.tscn` (cachee par defaut, `z_index=10` pour dessiner
    par-dessus les creatures peu importe l'ordre dans l'arbre).
  - **Non verifiable en headless** (meme limite que les autres anims de
    `ecran_tableau.gd`) : seule la STRUCTURE est testee
    (`smoke_test_phase7.gd`) + le comportement ISOLE de
    `TextureRectAnime.configurer_animation_unique()`
    (`smoke_test_phase8.gd`, testable car cette classe ne depend
    d'aucun autoload). Le rendu/timing reel (courbe du lancer, moment
    exact de l'absorption) est a valider par Mike via son raccourci.
  - **Piege GDScript trouve en ecrivant le test de
    `configurer_animation_unique()`** : un lambda (`func(): ...`)
    capture une variable locale PAR VALEUR (une copie au moment de la
    capture), pas par reference — assigner a l'interieur du lambda
    (ex. `termine = true`) ne modifie PAS la variable locale exterieure
    du meme nom. Utiliser un type reference (`Array`/`Dictionary`,
    ex. `var termine := [false]` puis `termine[0] = true`) pour qu'un
    callback puisse rapporter un resultat a l'appelant.
  - **Bug corrige : `catch.gif` s'affichait en boite noire en jeu.**
    Cause : `catch.gif` a 86 frames de 320x320px — `convertir_gifs.ps1`
    (voir plus haut) place toutes les frames cote a cote sur UNE SEULE
    rangee, donc la planche generee faisait 27520x320px, largeur qui
    depasse la limite materielle d'une texture 2D (generalement 8192
    ou 16384px selon le GPU/renderer) : la texture ne s'affiche pas
    correctement (boite noire) au lieu de planter clairement a
    l'import — Mike ne l'a decouvert qu'en testant en jeu. **Reflexe a
    garder pour tout futur GIF a beaucoup de frames et/ou grande
    resolution** (pas seulement les creatures) : `convertir_gifs.ps1`
    a maintenant un garde-fou (`$LARGEUR_MAX_SURE = 8192`) qui REDUIT
    automatiquement le nombre de frames par echantillonnage regulier
    (jamais juste les N premieres) si la planche depasserait cette
    largeur, plutot que de produire une texture corrompue. Les 151
    creatures n'ont jamais ete concernees (frames bien plus petites/
    moins nombreuses), seul `catch.gif` (effet ponctuel, gros GIF) a
    declenche ce cas.

**Piege Godot a connaitre : `Tween.set_parallel(false)` puis
`set_parallel(true)` a nouveau NE CREE PAS un vrai groupe sequentiel
distinct** si aucun tweener n'a ete ajoute pendant que le flag etait a
`false` — les deux groupes `parallel(true)` fusionnent silencieusement
en un seul, et pour une propriete ciblee par les DEUX groupes (ex.
`rotation` animee puis "annulee" vers sa valeur de depart), c'est le
DERNIER appel qui l'emporte pour toute la duree : l'animation entiere
peut sembler ne plus bouger du tout (bug trouve sur le wobble des
berries, `berry_item.gd`). Meme piege plus subtil sur
`tween_callback()`/`tween_interval()` places juste apres un seul
`set_parallel(false)` (sans second groupe `true`) : ils NE se
declenchent PAS forcement apres la fin du groupe parallele precedent
(verifie : un callback est parti ~1/3 avant la fin reelle du tween).
**Solution fiable dans les deux cas : `tween.chain()`** avant le
tweener qui doit demarrer un nouveau groupe sequentiel (`tween.chain().tween_property(...)`,
`tween.chain().tween_interval(...)`, `tween.chain().tween_callback(...)`),
plutot que de jongler avec `set_parallel(true/false)`.

**Reste a faire en Phase 8** (a voir avec Mike) :
- Contenu du placeholder gauche du Hub (pas encore decide).
- Remplacement des placeholders restants (`assets/ui/**/*.png`) des
  que Mike les fournit.
- Tests de bout en bout supplementaires si de nouveaux cas limites
  emergent en playtest reel avec l'enfant.

**Piege a connaitre : Timer cree dans un script de test headless**
(`extends SceneTree`) — `Timer.start()` echoue si le noeud n'est pas
"inside tree", et `add_child()` sur un noeud ajoute a `root` pendant
`_initialize()` ne rend PAS le noeud "inside tree" avant la frame
suivante (meme famille de piege que `@onready`, voir plus bas) —
`await process_frame` apres `root.add_child(...)` avant de tester
quoi que ce soit qui depend d'etre dans l'arbre (voir
`scripts/tests/smoke_test_phase8.gd`). **Precision importante** : apres
ce `await process_frame`, Godot a bien appele `_ready()` tout seul —
ne PAS le rappeler manuellement a la suite (`node.new(); root.add_child(node);
await process_frame; node._ready()`), ca connecte les signaux une 2e
fois et plante ("already connected", trouve dans
`smoke_test_raffinements_menu.gd` en branchant le hook de son de clic
de `AudioManager` sur `SceneTree.node_added`). L'appel manuel de
`_ready()` ne reste necessaire QUE si le noeud n'est jamais ajoute a
l'arbre du tout (cas `AudioManagerScript.new()` sans `add_child`,
pattern utilise ailleurs pour tester une methode isolement).

**Piege GDScript a connaitre avant de coder un nouveau composant
reutilisable** : ne pas utiliser `@onready var x = %NodeName` pour un
composant configure juste apres `instantiate()`/`add_child()` — resoudre
`%NodeName` a la demande dans la fonction de configuration a la place
(voir [docs/phases/phase_03_hub_principal.md](docs/phases/phase_03_hub_principal.md)
pour le detail du bug — retrouve en Phase 6 sur les 8 widgets de
`scripts/tableau/`, meme cause). Et ne jamais utiliser `assert()` dans
un script de test headless (bloque indefiniment sans debugger attache)
— utiliser un helper `_verifier(condition, message)` qui `print()` +
`quit(1)`.

**Autre piege a connaitre** : un nombre entier lu depuis un fichier
JSON revient en `float` (JSON ne distingue pas int/float). Toujours
passer par `int(...)` avant de **comparer** (`get_stage_creature` etc.,
Phase 4) ET avant d'**afficher** (`str(int(valeur))`, pas `str(valeur)`
— trouve en Phase 6 sur `widget_pair_impair.gd`/
`widget_croissant_decroissant.gd`, affichait "4.0" au lieu de "4").

**Reflexe SaveManager** : toute nouvelle methode qui mute `data` doit
se terminer par `save_game()` — `capturer_creature()` et
`marquer_vue()` ont toutes les deux ete ecrites en Phase 1 sans cet
appel, et le bug est reste invisible (silencieux, pas d'erreur) jusqu'a
ce qu'une phase bien plus tardive les utilise pour de vrai (Phase 6
pour la premiere, Phase 7 pour la seconde). Avant d'ajouter une methode
mutative a `SaveManager`, verifier explicitement l'appel a
`save_game()`.

## Decoupage en phases

1. **Phase 1 - Fondations** — termine, voir
   [docs/phases/phase_01_fondations.md](docs/phases/phase_01_fondations.md).
2. **Phase 2 - Intro et starter** — termine, voir
   [docs/phases/phase_02_intro_starter.md](docs/phases/phase_02_intro_starter.md).
3. **Phase 3 - Hub principal** — termine, voir
   [docs/phases/phase_03_hub_principal.md](docs/phases/phase_03_hub_principal.md).
4. **Phase 4 - Roster et evolutions** — termine, voir
   [docs/phases/phase_04_roster_evolutions.md](docs/phases/phase_04_roster_evolutions.md)
   et [docs/phases/phase_04_bis_berries_feelgood.md](docs/phases/phase_04_bis_berries_feelgood.md)
   (surnom, barre XP animee, animation d'attribution d'XP, systeme de
   berries avec glisser-depose et sprites "glow", creature principale).
5. **Phase 5 - Selection de niveau** — termine, voir
   [docs/phases/phase_05_selection_niveau.md](docs/phases/phase_05_selection_niveau.md).
6. **Phase 6 - Scenes de tableau** — termine, voir
   [docs/phases/phase_06_scenes_tableau.md](docs/phases/phase_06_scenes_tableau.md)
   (8 widgets de reponse reutilisables + orchestrateur commun, 80
   niveaux de contenu, XP/berries branches pour de vrai, creature
   principale affichee cote joueur).
7. **Phase 7 - Logique de rencontre/capture** — termine, voir
   [docs/phases/phase_07_rencontre_capture.md](docs/phases/phase_07_rencontre_capture.md)
   (tirage aleatoire sans repetition, association fixe creature/tableau,
   capture reelle a la reussite).
8. **Phase 8 - Polish et integration finale** (en cours, derniere,
   pas encore archivee) : voir "Deja fait en Phase 8" / "Reste a faire
   en Phase 8" plus haut.

Une phase = une grande etape ci-dessus (pas de sous-decoupage
documentaire separe).

## Protocole d'archivage (a suivre a CHAQUE phase completee)

1. Archiver les notes techniques de la phase terminee dans
   `docs/phases/phase_NN_nom.md` (decisions techniques, fichiers crees,
   particularites a retenir pour la suite).
2. Nettoyer ce `CLAUDE.md` : ne garder que l'etat actuel (court), la liste
   des phases avec un lien vers leur archive, et les instructions pour la
   phase suivante. Ne jamais laisser le detail technique s'accumuler ici.
3. But : eviter que ce fichier grossisse et gonfle les tokens consommes a
   chaque session.

## Demandes d'assets UI en cours de route

Des qu'une phase a besoin d'un visuel d'UI qui n'existe pas (icone,
bouton, fond, cadre...), s'arreter et le demander a Mike explicitement :
nom de fichier + emplacement attendu, format (PNG transparent, etc.),
dimensions exactes en pixels. En attendant, utiliser un placeholder
(`ColorRect` + texte du nom de fichier attendu) pour que le jeu reste
testable. Note : les sprites de creatures (`assets/creatures/c*.png`)
suivent deja ce patron via `scripts/util/sprite_util.gd`
(`SpriteUtil.charger_texture(id)` retourne `null` si le fichier n'existe
pas encore — au composant appelant d'afficher un placeholder, voir
`scripts/components/carte_creature.gd` pour un exemple).

## Chaines d'evolution des creatures

`data/creatures.json` couvre deja NATIVEMENT les chaines d'evolution
(pas de champ separe a ajouter) : chaque bloc du tableau `"creatures"`
represente toute une ligne d'evolution (1 a 3 stades), pas une seule
creature — le lien "evolue vers" se fait juste en mettant les stades
dans le meme bloc (`forms`/`names` avec une entree par stade). Guide
complet en langage simple pour Mike :
[docs/evolutions.md](docs/evolutions.md).

## Reflexe de verification (Phase 8 et suite)

Mike a demande de ne PLUS lancer le jeu en fenetre/prendre des captures
d'ecran pour verifier (economie de tokens, il teste lui-meme via son
raccourci Bureau `lancer_jeu.bat`). Verification headless uniquement :
`godot --headless --path <projet> --import` (0 erreur) + suite de
smoke tests (`scripts/tests/smoke_test_*.gd`). Ne pas ouvrir les
fichiers PNG/image de Mike avec l'outil de lecture non plus (voir
"Vigilance IP/legal" plus haut) — verifications non visuelles
seulement, sauf demande explicite contraire.
