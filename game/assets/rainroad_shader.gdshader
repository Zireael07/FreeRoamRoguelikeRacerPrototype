shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_lambert,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_emission : hint_default_black;
uniform vec4 emission : source_color;
uniform float emission_energy;
uniform float puddle_size : hint_range(0,1);
uniform vec2 roughness_scale;
uniform vec2 roughness_offset;
//uniform vec4 roughness_texture_channel;
uniform sampler2D reflect_texture: hint_default_black;
varying vec3 uv2_triplanar_pos;

void vertex() {
	//UV=UV*uv1_scale.xy+uv1_offset.xy;
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	//uv2_power_normal=pow(abs(mat3(MODEL_MATRIX) * NORMAL), vec3(uv2_blend_sharpness));
	uv2_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xyz; //* uv2_scale + uv2_offset;
	//uv2_power_normal/=dot(uv2_power_normal,vec3(1.0));
	uv2_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}


vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	//float roughness_tex = dot(texture(reflect_texture,base_uv),roughness_texture_channel);
	//float roughness_tex = dot(texture(reflect_texture, base_uv), roughness_texture_channel);
	float reflect_tex = step(texture(reflect_texture, uv2_triplanar_pos.xz*roughness_scale.xy+roughness_offset.xy).r, 1.0-puddle_size);
	ROUGHNESS = reflect_tex * roughness;
	METALLIC = metallic * reflect_tex;
	//ROUGHNESS = roughness;
	SPECULAR = specular;
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	EMISSION = (emission.rgb*emission_tex)*emission_energy;
}
