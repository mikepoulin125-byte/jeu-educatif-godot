# Référence de style visuel — Aventure Mathématique

Document de référence graphique/design pour répliquer le style visuel du
menu principal et de l'UI du jeu (Hub, sélection de niveau, écran de
tableau). Ne couvre que l'apparence — aucune architecture ni code.

## 1. Identité générale

Style « carte au trésor / manuel scolaire chaleureux » : fond orangé à
bandes diagonales, panneaux blanc cassé à contour rouge épais et coins
très arrondis (« pilules »), texte avec contour noir pour rester lisible
sur fond coloré, animations courtes et rebondissantes plutôt que
linéaires. L'ensemble reste enfantin sans être criard — palette resserrée
autour de 4-5 teintes dominantes plutôt qu'un arc-en-ciel.

Résolution de référence : 1920×1080, mise à l'échelle « garder les
proportions » (letterboxing plutôt que déformation).

## 2. Palette de couleurs

**Rouge signature** (contours, accents, texte sur fond clair)
- Rouge principal : `#CC0000` — contour des boutons, panneaux, cartes.
- Rouge-brun (texte sur pilule blanche) : `#BF2614`.
- Rouge sombre (bandeaux XP/titre) : `#A32917` à 95 % d'opacité.

**Fond décoratif (bandes diagonales)**
- Fond de base : `#D94D29` (orange-rouge).
- Bande diagonale : `#A32917` (même teinte que les bandeaux — cohérence
  volontaire entre fond et bandeaux).
- Triangle d'accent (coin inférieur gauche) : `#F27847` (orange clair).

**Neutres**
- Blanc quasi pur (fond des boutons/panneaux) : `#FAFAFF`.
- Blanc translucide (pilules, contours de cadre) : blanc à 85–92 %
  d'opacité.
- Noir/anthracite translucide (bandeau d'info bas d'écran, cadre logo) :
  proche du noir à 55 % d'opacité.
- Ombres portées : noir à 25–30 % d'opacité, léger décalage vers le bas.

**Bleu (états de survol/sélection, texte de titres secondaires)**
- Fond survol/sélection : `#DEEBFF` (bleu très pâle).
- Fond pressé : bleu pâle un cran plus saturé.
- Texte de titre (résultats, cartes de niveau) : `#2966D9`.

**Vert (succès)**
- Fond « niveau réussi » : `#D1F5D9` (vert pâle).
- Contour « niveau réussi » : vert franc, plus saturé.

**Gris (désactivé)**
- Fond/contour grisés à 55–60 % d'opacité pour tout élément inactif.

**Brun/beige (badges de matière, chemin de terre)**
- Fond des badges circulaires : `#EBD3AD` (beige) au repos, s'éclaircit
  légèrement au survol, s'assombrit légèrement au clic.
- Chemin de terre (sentier décoratif) : brun `#9E7852` avec contour brun
  plus foncé `#6B4E33`.

**Couleurs d'accent ponctuelles**
- Or/jaune pour les compteurs (ex. numéro de question) : `#FFD966`.
- Jaune franc pour un effet ponctuel (ex. capture) : `#E6D94D`.

## 3. Typographie

- Police vedette : **Rubik, graisse Bold**, utilisée pour tous les
  titres, bandeaux et libellés importants (XP, titres d'écran, noms de
  personnage).
- Le reste du texte utilise la police système par défaut de l'UI — la
  police custom n'est pas imposée globalement, seulement sur les
  éléments qui doivent « percuter » visuellement.
- Tailles typiques : titres d'écran 30–34px, bandeaux XP 32px, boutons
  20–26px, corps de texte 18–20px, libellés secondaires/compteurs
  16–19px.
- **Contour de texte systématique** sur fond coloré/texturé : contour
  noir de 3 à 5px à ~35 % d'opacité (pas un contour dur à 100 %, un
  contour qui s'estompe pour rester doux). C'est ce qui permet au blanc
  du texte de rester lisible par-dessus le fond à bandes diagonales sans
  avoir besoin d'un bandeau opaque derrière chaque libellé.

## 4. Style des boutons

Deux familles de forme coexistent :

**Boutons « pilule »** (navigation : Retour, Quitter, Roster, bouton
Continuer) : coins très arrondis (rayon proche de la moitié de la
hauteur → forme en gélule), fond blanc à 92 % d'opacité, contour rouge
de 4px, texte rouge-brun. Compact (environ 140–190px de large sur
46–56px de haut).

**Boutons rectangulaires arrondis** (menu principal, cartes de niveau) :
coins arrondis mais pas en pilule complète (rayon ~20px sur une carte de
110px de haut, ~37px sur un bouton de menu de 74px de haut — le rayon
suit toujours grossièrement la moitié de la hauteur, donnant un aspect
« confortable » plutôt qu'anguleux). Fond blanc cassé, contour rouge de
5px, ombre portée légère (6-8px, noir 25-30%).

**États** (identiques sur les deux familles) :
- Normal : fond blanc cassé, contour rouge.
- Survol : fond teinté bleu très pâle, même contour rouge — pas de
  changement de contour, seulement le remplissage qui réagit.
- Pressé/clic : fond bleu un cran plus soutenu.
- Désactivé : fond et contour grisés, texte gris clair.
- Succès (cartes de niveau réussies) : bascule entièrement vers la
  palette verte (fond + contour), remplace le rouge plutôt que de
  s'y superposer.

**Animation d'interaction** (ressenti général, pas les valeurs
d'implémentation) : le bouton grossit très légèrement au survol (effet
« il vient vers toi »), se contracte franchement et rapidement au clic
(effet « pression physique »), puis rebondit pour revenir à sa taille de
survol/repos. Les transitions sont courtes (à peine perceptibles comme
durée, mais bien perceptibles comme mouvement) avec un easing doux en
sortie (« ease out ») plutôt que linéaire — jamais de saut brutal.

## 5. Cadres et badges — le motif « double contour »

Motif visuel récurrent et distinctif du projet, réutilisé sur les
badges de matière du Hub :

1. Un cercle extérieur épais en **contour blanc** (6px) sur fond beige.
2. À l'intérieur, décalé de quelques pixels, un **second anneau fin noir**
   (3px), séparé du bouton lui-même (un élément décoratif indépendant
   posé par-dessus, pas juste un deuxième contour sur le même objet).
3. Au centre, une pastille grise circulaire qui accueille l'icône du
   badge.

Effet recherché : un cadre « médaille »/« sceau » à deux liserés
(blanc épais dehors, noir fin dedans) plutôt qu'un contour unique. Ce
motif peut se réutiliser sur n'importe quel « badge » circulaire d'un
autre projet pour obtenir la même signature visuelle.

Les bandeaux (XP, titre d'écran) suivent une logique de cadre similaire
mais plus sobre : fond rouge sombre, un seul contour blanc épais (4px),
coins très arrondis, légère ombre portée.

## 6. Disposition générale

**Menu principal** : logo dans un cadre semi-transparent sombre en haut
à droite ; panneau de boutons (fond à bandes diagonales à l'intérieur
même du panneau) en bas à droite, empilement vertical des boutons avec
un espacement généreux entre eux. Beaucoup d'espace négatif — le fond
texturé occupe le reste de l'écran sans autre élément.

**Hub (écran d'accueil)** : bandeau XP en haut à gauche, bouton
« Roster » en haut à droite (style pilule), titre centré en haut. Grille
de badges de matière centrée à l'écran (4 colonnes), avec deux zones
décoratives qui encadrent la grille à gauche et à droite (illustration
de décor à gauche, créature principale du joueur à droite, toutes deux
verticalement centrées). Bandeau d'info tout en bas, pleine largeur,
fond sombre translucide.

**Sélection de niveau** : même ossature que le Hub (XP en haut à
gauche, retour en haut à droite, titre centré), grille de cartes de
niveau (5 colonnes × 2 rangées), reliées entre elles par un **chemin de
terre en pointillés** qui serpente entre les centres des cartes (courbe
légère, pas une ligne droite — le chemin « respire »). Un 11e niveau
« Examen » est positionné à part, sous la grille, plutôt que d'être
intégré dedans (pour ne pas casser la symétrie 5×2).

**Écran de tableau (exercice)** : fond sombre uni ou illustré,
personnage du joueur à un point fixe de l'écran, adversaire/créature à
un autre point fixe (positions choisies pour tomber sur des zones
« naturelles » du décor plutôt qu'au centre géométrique). Bandeau XP +
barre de compteur (berries) en haut à gauche, bouton Quitter en pilule
en haut à droite, question et feedback centrés. Écran de résultats en
fin de tableau : grand panneau pilule blanc centré, titre bleu, détails
en texte sombre, bouton de continuation en bas.

## 7. Fond décoratif à bandes diagonales

Motif de fond réutilisé sur plusieurs écrans (menu, Hub, sélection de
niveau) : un aplat de couleur de base (orange-rouge), traversé par une
large bande diagonale d'une teinte plus sombre (assortie aux bandeaux
d'UI), avec un triangle d'accent plus clair dans un coin (bas-gauche).
Effet « fanion/bannière » discret en arrière-plan, jamais assez
contrasté pour nuire à la lisibilité du texte par-dessus.

## 8. Chemin de niveaux (élément décoratif signature)

Ligne en tirets brun/beige qui relie les cartes de niveau entre elles,
avec un contour plus foncé dessiné juste en dessous (façon route de
carte au trésor). La ligne n'est jamais droite : elle « bombe »
légèrement entre chaque paire de cartes, en alternant le côté du
bombement pour un rendu naturel plutôt que mécanique. Purement
décoratif, jamais interactif.

## 9. Transitions d'écran

Transition en fondu vers le blanc, mais pas un fondu uniforme : un
**dégradé radial qui se referme depuis les bords de l'écran vers le
centre** (les coins/bords deviennent blancs avant le centre), courte
pause sur blanc plein, puis le nouvel écran apparaît et le même dégradé
se rouvre du centre vers les bords pour révéler la nouvelle scène.
Durée totale courte (autour d'une demi-seconde par sens), easing doux.
Une seule transition partagée pour tout le jeu, jamais de coupure
brutale entre deux écrans.

## 10. Micro-animations d'ambiance

Les éléments collectables/décoratifs (ex. items d'inventaire) ont un
tic d'ambiance discret plutôt qu'une boucle continue : une courte
secousse (légère rotation aller-retour + léger gonflement d'échelle),
puis une pause silencieuse de quelques secondes avant de recommencer.
Chaque instance démarre avec un délai aléatoire pour qu'un groupe
d'éléments identiques ne soit jamais synchronisé. Au survol, l'élément
grossit franchement, se soulève légèrement et passe au premier plan,
avec un léger effet de rebond à l'entrée et un retour plus doux à la
sortie.

## 11. Icônes et éléments vectoriels

Pas d'iconographie « ligne fine » ou minimaliste : les icônes occupent
des pastilles circulaires pleines (gris neutre par défaut en attendant
l'illustration finale), cohérentes avec le motif de badge à double
contour. Les compteurs numériques (question, score) utilisent une
couleur or/jaune chaude qui tranche volontairement avec le rouge
dominant, pour signaler « information à part » plutôt que chrome
d'interface.

## Résumé pour réplication rapide

| Élément | Valeur |
|---|---|
| Couleur d'accent principale | Rouge `#CC0000` |
| Fond de panneau | Blanc cassé `#FAFAFF`, 85-92% opacité en pilule |
| Fond décoratif d'écran | Orange `#D94D29` + bande `#A32917` + triangle `#F27847` |
| Police vedette | Rubik Bold |
| Contour de texte | Noir, 3-5px, ~35% opacité |
| Boutons pilule | Contour rouge 4px, coins ~moitié de la hauteur |
| Boutons rectangulaires | Contour rouge 5px, coins ~20-37px, ombre 6-8px |
| Badge à double contour | Anneau blanc 6px extérieur + anneau noir 3px intérieur séparé |
| Survol bouton | Fond bleu pâle `#DEEBFF`, léger agrandissement |
| Succès | Bascule vers palette verte (`#D1F5D9` / vert franc) |
| Transition d'écran | Fondu blanc radial bords→centre, ~0.35s par sens |
| Chemin décoratif | Tirets bruns avec contour foncé, courbe légère alternée |
