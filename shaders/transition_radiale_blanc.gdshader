shader_type canvas_item;
// Vignette radiale blanche animee, utilisee pour les transitions entre
// le menu, l'ecran de chargement et le jeu.
//
// "progression" (0..1) controle jusqu'ou le blanc a gagne depuis les
// bords vers le centre :
//   - progression = 0.0 -> ecran transparent (rien de blanc visible)
//   - progression = 1.0 -> ecran entierement blanc
//   - entre les deux, une couronne blanche part des bords et grandit
//     vers le centre (le centre est donc le DERNIER a disparaitre)
//
// Pour un fade IN (le blanc se retire, centre en premier), il suffit
// d'animer "progression" de 1.0 vers 0.0 avec ce meme shader — la
// formule est symetrique, pas besoin d'un second shader.

uniform float progression : hint_range(0.0, 1.0) = 0.0;
uniform float largeur_degrade : hint_range(0.01, 1.0) = 0.35;
uniform vec2 taille_ecran = vec2(1920.0, 1080.0);

void fragment() {
	vec2 centre_pixels = taille_ecran * 0.5;
	vec2 pos_pixels = UV * taille_ecran - centre_pixels;
	float rayon_max = length(centre_pixels);
	float dist = length(pos_pixels) / rayon_max;  // 0 au centre, 1 au coin le plus loin

	float seuil = 1.0 - progression;
	float bord_interieur = seuil - largeur_degrade * 0.5;
	float bord_exterieur = seuil + largeur_degrade * 0.5;

	float alpha = smoothstep(bord_interieur, bord_exterieur, dist);

	COLOR = vec4(1.0, 1.0, 1.0, alpha);
}
