shader_type spatial;
render_mode unshaded;

uniform vec3 cam;


void fragment() {
	vec4 screen =textureLod( SCREEN_TEXTURE, SCREEN_UV, 0.0);
	
	vec2 uv = SCREEN_UV;
	vec2 uv_mv = vec2(cam.x, cam.y);
	
	vec3 c = textureLod(SCREEN_TEXTURE,uv+uv_mv,0.0).rgb;
	vec4 ghost = vec4(c.rgb, 0.5);
	
	//ALBEDO = screen.rgb;
	
	//ALBEDO = ghost.rgb;
	
	//if (ghost.r > screen.r && ghost.b > screen.b)
	//	ALBEDO = vec3(1.0, 1.0, 1.0);
		
	//if (screen.r > 0.5)
	//	ALBEDO = vec3(1.0, 0.0, 0.0);
		//ALPHA = 0.5;
	
	vec3 bright = vec3(1.2, 1.2, 1.2);
	
	//ALBEDO = ghost.rgb;
	
	//ALBEDO = screen.rgb + ghost.rgb;
	
	ALPHA = ghost.a;
	
	//ALBEDO.rgb=mix(screen.rgb, ghost.rgb, 0.3);
	
	ALBEDO = ghost.rgb*bright;
	
	//ALBEDO = screen.rgb;
}
