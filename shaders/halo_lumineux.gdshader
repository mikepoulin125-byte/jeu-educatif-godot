shader_type canvas_item;
// Halo lumineux radial (blanc/rose), utilise derriere une creature du
// Roster quand elle recoit une berry. "intensite" (0..1) pilote
// l'opacite du halo ; anime en 0 -> 1 -> 0 par tween au moment du drop.

uniform float intensite : hint_range(0.0, 1.0) = 0.0;
uniform vec4 couleur_halo : source_color = vec4(1.0, 0.85, 0.9, 1.0);

void fragment() {
	vec2 centre = vec2(0.5, 0.5);
	float dist = length(UV - centre) * 2.0;  // 0 au centre, ~1 au bord
	float alpha = (1.0 - smoothstep(0.0, 1.0, dist)) * intensite;
	COLOR = vec4(couleur_halo.rgb, alpha);
}
