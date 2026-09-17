shader_type canvas_item;
// Fond a bandes diagonales bicolores + triangle clair en coin, dans
// l'esprit du hub de reference envoye par Mike (langage visuel generique
// : bandes diagonales + palette vive, AUCUN element specifique reproduit).
// Parametrable par uniform pour changer facilement la palette plus tard.

uniform vec4 couleur_fond : source_color = vec4(0.85, 0.30, 0.16, 1.0);
uniform vec4 couleur_bande : source_color = vec4(0.64, 0.16, 0.09, 1.0);
uniform vec4 couleur_triangle : source_color = vec4(0.95, 0.47, 0.28, 1.0);
uniform float largeur_bande : hint_range(0.0, 1.0) = 0.20;
uniform float position_bande : hint_range(-1.0, 1.0) = 0.18;
uniform float taille_triangle : hint_range(0.0, 1.0) = 0.30;

void fragment() {
	vec2 uv = UV;
	vec4 couleur = couleur_fond;

	float diagonale = uv.x - uv.y;
	float decalage = diagonale - position_bande;
	if (decalage > 0.0 && decalage < largeur_bande) {
		couleur = couleur_bande;
	}

	if (uv.x + uv.y < taille_triangle) {
		couleur = couleur_triangle;
	}

	COLOR = couleur;
}
