//based on https://www.reddit.com/r/godot/comments/bxfyws/heres_a_dithered_opacity_aka_hashed_transparency/

// My custom shader for implementing dithered alpha
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;

// Texture maps
uniform sampler2D texture_albedo : hint_albedo;
//uniform sampler2D texture_masks : hint_white;
//uniform sampler2D texture_normal : hint_normal;

// Parameters
uniform vec4 albedo : hint_color;
uniform float specular = 0.5;
uniform float metallic = 0.0;
uniform float roughness : hint_range(0,1) = 0.5;
uniform float normal_strength : hint_range(0,2) = 1.0;
uniform float alpha_clip: hint_range(0,1) = 0.0;
uniform float emission_energy;

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	//vec4 masks_tex = texture(texture_masks, UV);
	float alpha = albedo_tex.a;
		
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic; //* masks_tex.r;
	ROUGHNESS = roughness; //* masks_tex.g;
	EMISSION = vec3(0.0, 0.0, 1.0)*emission_energy;
	//NORMALMAP = texture(texture_normal, UV).rgb;
	//NORMALMAP_DEPTH = normal_strength;
	
	// Fancy dithered alpha stuff
	float opacity = albedo_tex.a;
	int x = int(FRAGCOORD.x) % 4;
	int y = int(FRAGCOORD.y) % 4;
	int index = x + y * 4;
	float limit = 0.0;

	if (x < 8) {
		if (index == 0) limit = 0.0625;
		if (index == 1) limit = 0.5625;
		if (index == 2) limit = 0.1875;
		if (index == 3) limit = 0.6875;
		if (index == 4) limit = 0.8125;
		if (index == 5) limit = 0.3125;
		if (index == 6) limit = 0.9375;
		if (index == 7) limit = 0.4375;
		if (index == 8) limit = 0.25;
		if (index == 9) limit = 0.75;
		if (index == 10) limit = 0.125;
		if (index == 11) limit = 0.625;
		if (index == 12) limit = 1.0;
		if (index == 13) limit = 0.5;
		if (index == 14) limit = 0.875;
		if (index == 15) limit = 0.375;
	}
	// Is this pixel below the opacity limit? Skip drawing it
	if (opacity < limit || opacity < alpha_clip)
		discard;
}