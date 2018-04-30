shader_type spatial;
render_mode unshaded;

uniform vec3 cam;


void fragment() {
	vec4 screen =textureLod( SCREEN_TEXTURE, SCREEN_UV, 0.0);
        //float depth = textureLod(DEPTH_TEXTURE,SCREEN_UV,0.0).r;
		//vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV, depth, 1.0);
		//upos = vec4(SCREEN_UV, depth, 1.0);
        //vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth*2.0-1.0,1.0);
        //vec3 pixel_position = upos.xyz/upos.w;
	
	//COLOR = screen;
	
	vec2 uv = SCREEN_UV;
	vec2 uv_mv = vec2(cam.x, cam.y);
	
	//uv = mix(uv, uv_mv, 0.1);
	//uv.y += cam.y+0.02;
	//uv.x += sin(uv.y*frequency+TIME)*depth;
	//uv.x = clamp(uv.x,0,1);
	
	//uv = uv+uv_mv;
	
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
		
		//ALBEDO = pixel_position;
		//ALBEDO = pixel_position+cam;
		//ALBEDO = pixel_position+cam+screen.rgb;
		//ALPHA = 1.0;
}