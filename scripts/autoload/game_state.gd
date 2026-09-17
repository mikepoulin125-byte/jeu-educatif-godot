extends Node
## Etat de session transitoire (pas sauvegarde), pour passer de l'info entre scenes.
## Ex.: quelle matiere/niveau vient d'etre choisi avant de charger la scene de tableau.

var matiere_courante_id: String = ""
var niveau_courant_id: String = ""

## Scene a charger apres l'ecran de chargement (EcranChargement.tscn),
## fixee juste avant d'y entrer (voir menu_principal.gd).
var scene_suivante: String = ""
