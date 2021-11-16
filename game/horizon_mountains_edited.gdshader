/*
	遠景山シェーダー by あるる（きのもと 結衣） @arlez80
	Background Mountain Shader by Yui Kinomoto

	MIT License
*/

shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform float mountain_distance = 2000.0;
uniform sampler2D mountain_texture : hint_albedo;
uniform sampler2D sand_texture : hint_albedo;
uniform sampler2D height_map : hint_black;
uniform float height = 11.0;
uniform vec4 aerial_perspective_color : hint_color = vec4( 0.1411764705882353, 0.41568627450980394, 0.6705882352941176, 1.0 );
uniform vec2 mountain_uv_scale = vec2( 25.0, 25.0 );
uniform vec2 sand_uv_scale = vec2( 100.0, 100.0 );

void vertex( )
{
	float r = atan( VERTEX.z, VERTEX.x );
	float dist = length(UV - vec2(0.5, 0.5));
	//CUSTOM - step creates big mountains on map edges
	VERTEX.y = texture( height_map, UV ).r * height * step(0.5, dist);
	NORMAL = vec3( 0.0, 1.0, 0.0 );
}

void fragment( )
{
	float dist = length(UV - vec2(0.5, 0.5));
	ALBEDO = mix(
		mix(
			texture( mountain_texture, UV * mountain_uv_scale )
		,	texture( sand_texture, UV * sand_uv_scale )
		,	clamp( pow( texture( height_map, UV * 1.1 ).r * 1.4, 6.0 ), 0.0, 1.0 )
		).rgb
	,	aerial_perspective_color.rgb
	,	dist * 0.8
	);
	DEPTH = clamp( 0.99999 + dist * 0.00001, 0.0, 1.0 );
}
