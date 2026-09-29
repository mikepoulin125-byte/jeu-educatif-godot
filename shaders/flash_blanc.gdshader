shader_type canvas_item;
// "Flash" blanc d'impact (creature sauvage touchee par une bonne
// reponse) : melange la couleur du sprite vers du blanc pur en
// preservant sa transparence (alpha). "intensite" (0..1) pilote le
// melange ; anime rapidement en 0 -> 1 -> 0 par tween au moment de
// l'impact (voir ecran_tableau.gd::_declencher_impact()).

uniform float intensite : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 couleur = texture(TEXTURE, UV);
	COLOR = vec4(mix(couleur.rgb, vec3(1.0), intensite), couleur.a);
}
