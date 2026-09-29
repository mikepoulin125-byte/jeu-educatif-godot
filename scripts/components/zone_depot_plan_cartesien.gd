class_name ZoneDepotPlanCartesien
extends Control
## Cible de glisser-depose pour le widget plan_cartesien (tableau
## "placer_point", badge 4) : accepte uniquement les donnees de type
## "creature_plan_cartesien" (voir creature_deplacable.gd) et relaie
## l'evenement via un signal, pour que la logique reste dans
## widget_plan_cartesien.gd (meme pattern que zone_drop_creature.gd).
##
## IMPORTANT : ce noeud doit rester petit/localise (juste la zone du
## plan), jamais plein ecran. `_can_drop_data()` avec un mouse_filter
## autre que IGNORE rend le noeud "visible" au clic - sur un noeud
## plein ecran (comme la racine du widget, qui couvre tout l'ecran par
## anchors), ca a deja fait regresser le bouton Quitter/DEV (bug
## documente dans CLAUDE.md : mouse_filter STOP sur une zone plein
## ecran ajoutee par-dessus avale tous les clics, meme au-dessus de
## boutons positionnes ailleurs a l'ecran).

## "index" : indice de la creature deposee (voir creature_deplacable.gd),
## pour que le widget sache laquelle deplacer quand plusieurs creatures
## sont a placer sur le meme plan (tableau 5+).
signal creature_deposee(index: int)

var actif: bool = false

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return actif and typeof(data) == TYPE_DICTIONARY and data.get("type") == "creature_plan_cartesien"

func _drop_data(_at_position: Vector2, data) -> void:
	creature_deposee.emit(int(data.get("index", 0)))
