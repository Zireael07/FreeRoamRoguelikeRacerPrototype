shader_type canvas_item;

uniform vec4 sky_color_day : source_color = vec4(0.4, 0.7, 0.7, 1.0);
uniform vec4 sky_color_night : source_color = vec4(0, 0, 0.2, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.8, 0.2, 0.1, 0.35);
uniform vec4 day_horizon_color: source_color = vec4(0.55, 0.82, 0.91, 0.35);
//uniform vec4 green_color : source_color = vec4(0, 0.3, 0, 0.5);
uniform vec4 sun_color1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 sun_color2 : source_color = vec4(1.0, 0.05, 0.0, 0.75); // yellow (1.0, 0.75, 0.0, 0.75)

// Other params
uniform float horizon_size = 0.015; //needs to be small because otherwise it curves visibly 
uniform float sun_size1 = 0.01;
uniform float sun_size2 = 0.2;

//new
uniform vec2 sun_pos = vec2(0.4, 0.2); //0.0);
//bounds of actually visible area
uniform vec2 bounds = vec2(0.5, 0.5);

void fragment() {
	// base color, day/night
	vec4 skyc = mix(sky_color_day, sky_color_night, clamp(sun_pos.y,0,1));
	
	// sun color, high=color1, low=color2
	vec4 sunc_mix = mix(sun_color1, sun_color2, clamp(pow(sun_pos.y, 4), 0,1));
	// pow(uv.y,6) works amazingly for slowing down the transitions
	//high = sunsize1, low=sunsize2
	float sun_size = mix(sun_size1, sun_size2, clamp(pow(sun_pos.y, 6), 0,1));
	
	//draw sun
	// based on https://www.shadertoy.com/view/MdtXD2
	//float len = distance(UV, vec2(sun_pos.x*bounds.x, sun_pos.y*bounds.y));
	//float len = length(UV-sun_pos*bounds);
	//float sun = max(1.0 - (sun_size*200.0 * len), 0.0);
	//float sun = max(1.0 - (1.0 + sun_size*200.0 + 1.0 * UV.y) * len, 0.0);
	
	//based on https://www.shadertoy.com/view/MsVSWt
	float sun = 1.0 - distance(UV, vec2(sun_pos.x*bounds.x, sun_pos.y*bounds.y));
    sun = clamp(sun,0.0,1.0);
	sun = pow(sun,100.0);
	sun *= 100.0*sun_size;
    sun = clamp(sun,0.0,1.0);
	
	vec4 sunc = sunc_mix *sun;
	
	// horizon color
	vec4 hc = mix(day_horizon_color, horizon_color, clamp(pow(sun_pos.y, 2), 0,1));
	
	//mix in some sky color (to make horizon show later)
	hc = mix(hc, skyc, 1.0-sun_pos.y);
	
	// mix in sun color for an amazing sunset
	hc = mix(hc, mix(hc, sunc_mix, clamp(pow(sun_pos.y, 6), 0.0, 0.6)), sun_pos.y);
	// don't draw horizon if past sunset
	hc = mix(skyc, hc, clamp(1.0-(sun_pos.y-0.4), 0.0, 1.0));

	//alpha	
	//hc = mix(skyc.rgba, hc.rgba, horizon_color.a);
	//hc.a = smoothstep(hc.a, hc.a, 1.0-sun_pos.y);
	
	
	
	
	//draw the horizon
	//float top = bounds.y-horizon_size;
	// this ought to be slower than other transitions
	float top = bounds.y-horizon_size*pow(clamp(sun_pos.y, 0.0, 1.0), 8);
	//simple gradient
	//vec4 outc = hc; 
	vec4 outc = mix(skyc, hc, smoothstep(top, bounds.y, UV.y));
	//outc = mix(outc, skyc, smoothstep(bounds.y, bounds.y+horizon_size, UV.y));
	
	COLOR = mix(outc, sunc, sun);
	
	//COLOR = outc.rgba+sunc;
	//COLOR = sunc;
	//why do we mix in the green?
	//COLOR = mix(COLOR,mix(COLOR, green_color.rgba, green_color.a), clamp(sun_pos.y, 0, 1));
	
//	vec4 skyc = mix(sky_color_night,sky_color_day,clamp(sun_altitude,0,1));
//
//	
//	vec4 sun1 = mix(sun_color1,sun_color2,clamp(-sun_altitude+1.0,0,1));
//	vec4 sun2 = mix(sun_color2,sun_color1,clamp(sun_altitude,0,1));
//	float sunhide = clamp((sun_altitude+0.1)*10.0,0,1);

	// horizon color
//	vec4 hc = horizon_color;//mix(horizon_color, sun2*sun1, clamp(sun_dot1,0,1));
//	hc = mix(hc,sky_color_night,clamp(-sun_altitude,0,1));
//	hc = mix(hc,sky_color_day,clamp(sun_altitude,0,1));
//	//hc = mix(hc,(sun1+sun2)/1.75, clamp(sun_dot*abs(sun_dot) * clamp(1-abs(sun_altitude),0,1),0,1));
//
//	skyc = mix(skyc, mix(skyc, sun2, sun_color2.a*sunhide), 0.11);
//	skyc = mix(skyc, mix(skyc, sun1, sun_color1.a*sunhide), 0.1);
	//float y = sun_altitude/horizon_size;
	//COLOR = skyc.rgba;
	//COLOR = mix(skyc.rgba, mix(skyc.rgba, hc.rgba, horizon_color.a), clamp(1.0-y, 0, 1));

	//COLOR = mix(COLOR,mix(COLOR, ground_color.rgba, ground_color.a), clamp(0.0-y, 0, 1));
}
