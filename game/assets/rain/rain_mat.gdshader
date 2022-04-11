shader_type spatial;
render_mode cull_disabled, diffuse_lambert, unshaded;

uniform vec4 albedo : hint_color;
uniform float scale = 1.0;
uniform sampler2D rain_texture;

void vertex() {
	UV += INSTANCE_CUSTOM.xy;
	
	VERTEX *= scale;
	
	MODEL_MATRIX[2].xyz = normalize((MODEL_MATRIX[3] - INV_VIEW_MATRIX[3]).xyz) * vec3(1,0,1);
	MODEL_MATRIX[0].xyz = cross(MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz);
	
	MODELVIEW_MATRIX = VIEW_MATRIX * MODEL_MATRIX;
}


void fragment() {
	vec2 base_uv = UV;
	ALBEDO = albedo.rgb;
	ALPHA = texture(rain_texture, base_uv).a;
	//TRANSMISSION = vec3(1.0);
}