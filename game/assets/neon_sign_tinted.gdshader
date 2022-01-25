shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_emission : hint_black_albedo;
uniform vec4 emission : hint_color;
uniform float emission_energy;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform vec4 mask_color : hint_color;
uniform vec4 modulate : hint_color;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}




void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	//new!
	float fac = 1.0;
	//https://randommomentania.com/2019/07/godot-color-mask-tutorial/
	if (length(abs(mask_color - albedo_tex)) >= 0.1)
	{
		fac = 0.0;
	}
	vec3 alb = albedo.rgb * albedo_tex.rgb; 
	ALBEDO = mix(alb, modulate.rgb, fac); 
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	vec3 em = (emission.rgb*emission_tex)*emission_energy;
	EMISSION = mix(em, modulate.rgb, fac);
}
