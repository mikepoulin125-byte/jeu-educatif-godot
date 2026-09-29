# Comment définir les évolutions des créatures

**Ce document est un guide de lecture, pas une source de données.** Le
jeu ne lit que `data/creatures.json` — tout ce qui compte doit être
écrit là-bas. Ce fichier explique juste, en langage simple, comment lire
et modifier `data/creatures.json` pour définir les 151 créatures et
leurs évolutions, sans avoir à deviner la structure du JSON.

## L'idée de base : une "ligne" = une chaîne d'évolution complète

Le point le plus important à comprendre : **chaque bloc `{ ... }`
dans `data/creatures.json` ne représente PAS une seule créature, mais
toute sa chaîne d'évolution** (1, 2 ou 3 stades). Il n'y a donc pas de
champ du genre `"evolue_vers": "creature_02"` à remplir quelque part —
le lien entre une créature et sa forme évoluée se fait simplement en
les mettant **dans le même bloc**, à des stades différents.

Exemple déjà présent dans le fichier :

```json
{
    "id": "creature_01",
    "stages": 3,
    "types": ["eau"],
    "starter": true,
    "forms":  { "stage1": "c1", "stage2": "c2", "stage3": "c3" },
    "names":  { "stage1": "Creature 1", "stage2": "Creature 1 Evo", "stage3": "Creature 1 Evo Finale" },
    "description": "Description a venir."
}
```

Il s'agit d'UNE seule ligne d'évolution à 3 stades : `c1` (bébé) qui
devient `c2` (évolution 1) qui devient `c3` (évolution finale). C'est
tout le "lien d'évolution" — rien d'autre à câbler.

## Les champs, un par un

| Champ | Rôle | Exemple |
|---|---|---|
| `id` | Identifiant interne unique de la LIGNE d'évolution (pas d'un sprite). Sert dans les sauvegardes — ne jamais le renommer une fois utilisé. | `"creature_01"` |
| `stages` | Combien de stades cette ligne a : `1` (pas d'évolution), `2` ou `3`. | `3` |
| `types` | Type(s) élémentaire(s), utilisé par la matière "Possible/impossible" (`data/types.json`). | `["eau"]` |
| `starter` | `true` si cette ligne est proposée au choix de départ (section 5 de la spec). Quelques lignes seulement, pas les 151. | `true` |
| `forms` | Pour chaque stade, QUEL sprite (`c1` à `c151`) afficher. | `{ "stage1": "c1", "stage2": "c2" }` |
| `names` | Pour chaque stade, quel NOM afficher. | `{ "stage1": "...", "stage2": "..." }` |
| `description` | Texte libre affiché sur la carte de la créature. | `"..."` |

`forms` et `names` ont toujours exactement `stages` entrées (une ligne
à 2 stades a `stage1`/`stage2`, jamais `stage3`).

## La seule règle stricte à respecter : les numéros de sprite

Les sprites vont de `c1` à `c151` (voir
[assets/creatures/LISEZ-MOI.txt](../assets/creatures/LISEZ-MOI.txt)
pour le format des fichiers). **Chaque numéro ne doit être utilisé
QU'UNE SEULE FOIS dans tout le fichier**, tous stades et toutes lignes
confondus — jamais deux stades différents (même dans deux lignes
différentes) ne pointent vers le même `cN`.

Concrètement : si tu as 151 sprites, la SOMME des `stages` de toutes
tes lignes doit faire exactement 151. Par exemple :
- 30 lignes à 3 stades = 90 sprites
- 20 lignes à 2 stades = 40 sprites
- 21 lignes à 1 stade = 21 sprites
- Total : 90 + 40 + 21 = 151 lignes de créatures, 151 sprites, aucun
  numéro répété.

(Ce découpage 30/20/21 n'est qu'un exemple pour illustrer le calcul —
libre à toi de choisir n'importe quelle répartition tant que le total
des `stages` fait 151.)

## Ce qui n'a PAS besoin d'être dans le JSON

- **Le coût en XP pour évoluer** : fixe et identique pour toutes les
  créatures, déjà dans le code (`SaveManager` :
  300 XP pour passer au stade 2, 500 XP pour passer au stade 3). Rien
  à ajouter dans `creatures.json` pour ça.
- **Le sprite "glow"** (créature qui brille après 20 berries) : un
  fichier optionnel de plus par stade, `cN_glow.png` dans le même
  dossier que `cN.png` — pas un champ JSON séparé, voir le commentaire
  en tête de `data/creatures.json`.

## Étapes concrètes pour ajouter une ligne d'évolution

1. Choisis combien de stades elle a (1, 2 ou 3).
2. Réserve ce nombre de numéros `cN` **encore inutilisés** ailleurs
   dans le fichier (ex. si `c1` à `c6` sont déjà pris par
   `creature_01`/`02`/`03`, la prochaine ligne commence à `c7`).
3. Ajoute un nouveau bloc `{ ... }` dans le tableau `"creatures"` avec
   un `id` unique, `stages`, `types`, `starter` (`true` seulement pour
   quelques-unes), `forms`/`names` avec une entrée par stade, et une
   `description`.
4. Dépose les fichiers `assets/creatures/cN.gif` (ou `.png`)
   correspondants (voir
   [assets/creatures/LISEZ-MOI.txt](../assets/creatures/LISEZ-MOI.txt)).
5. Relance le jeu via ton raccourci — rien d'autre à faire, aucune
   modification de code n'est nécessaire.
