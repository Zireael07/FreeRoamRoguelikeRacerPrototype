//based on https://www.shadertoy.com/view/Xtcczj
//adapted to work with the china sign mesh

shader_type spatial;

instance uniform vec2 offset;
instance uniform vec4 color: source_color;

//pseudo_western
//const int vMax = 3;
//const int hMax = 2;
//const float th = 1./2.5; // Line drawing probability threshold.


const int vMax = 4;
const int hMax = 4;
const float th = 1./3.; // Line drawing probability threshold.


// This is a rewrite of IQ's original. It's self contained, which makes it much
// easier to copy and paste. I've also tried my best to minimize the amount of 
// operations to lessen the work the GPU has to do, but I think there's room for
// improvement.
//
float n3D(vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
	const vec3 s = vec3(1, 57, 113);
	
	vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
	p -= ip; // Cell's fractional component.
	
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
	
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
	
}

float fbm(vec3 p, float sc){
    
    p *= sc;
    return n3D(p)*.57 + n3D(p*2.)*.28 + n3D(p*4.)*.15;
    
}

// vec2 to float hash formula.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(111.71, 157.93)))*43758.5453); }

// IQ's 2D unsigned box formula.
float sBox(vec2 p, vec2 b){ return length(max(abs(p) - b, 0.)); }


// Based on the imagery produced, this is probably self explanatory: Partition
// space into grid cells, then randomly render lines within the cell to produce
// a character. It's take most people ten minutes to code, but it took me much
// longer... It always does. Sigh! :D

float ChChars(vec2 p, bool flip){
    
    // The distance field value. Initiate it to the maximum.
    float d = 1.;
    
    // Line drawing probability threshold. If the unique ID of the line segment
    // exceeds this amount, render it. See the define above.
    //const float th = 1./3.;
    
    const float lw = .005;  // Line width -- Editable.
    const float sp = 1.45/9.; // Cell spacing -- Editable.
    // The individual line segment lengths: Exclude the cell edge spacing, then 
    // divide by 3. High school logic... that took me an embarassing amount of
    // time, due to the fact that the 4x4 horizontal lines and 4x4 vertical lines 
    // surround a "3x3" grid, and not a 4x4 one. It's not the first time I've made
    // that dumb mistake, and it won't be the last. :)
    const float ll = (1. - sp*2.)/3.;  
    
    // Unique character cell ID.
    vec2 ip = floor(p);
    
    // Local cell coordinates -- Edged out by the cell edge spacing.
    p -= ip + sp;
	
	//hack but works
	if (flip) p.y = 0.6-p.y;
   
    // Iterate through all the possible combinations of lines segments
    // in both the horizontal and the vertical. By the way, if rounded
    // edges weren't a requirement, this wouldn't be necessary... and
    // there might be some clever way to do it without the loops, but
    // nothing immediately came to mind. Either way, there's no 3D 
    // involved, so the GPU will have no trouble with this at all.
    for(int j = 0; j<vMax; j++){
        for(int i = 0; i<hMax; i++){          
            

            // Individual segment ID... I'm pretty sure that's right, but
            // I'd double check, just to make sure.
            vec2 ijp = ip*16. + vec2(float(i), float(j*4));

            float rndX= hash21(ijp); // Individual horizontal line ID.
            float rndY = hash21(ijp + .5); // Individual vertical line ID.

            // The line segment starting position. As we iterate throught the loop,
            // advance by the line length.
            vec2 q = p - vec2(float(i), float(j))*ll;

            // Draw the horizontal lines to the right of the first column.
            if(rndX>th && i>0){
               d = min(d, sBox(q + vec2(ll/2., 0), vec2(ll/2. + lw, lw)));
            }

            // Draw the vertical lines above the last row.
            if(rndY>th && j>0){
                d = min(d, sBox(q + vec2(0, ll/2.), vec2(lw, ll/2. + lw)));
            }  

        }
    }
    
    // Return the 2D distance field.
    return d;
    
    
}

//need to pass in the instance uniform because it doesn't compile otherwise
vec3 makeChars(vec2 uv, bool flip, vec3 bg_color) {
	// Scaling and movement. 
	//dunno why the vec 0, .5 on shadertoy but it's not necessary in Godot
    //vec2 p = UV*5. + vec2(0, .5) + vec2(1, 0); //*TIME;
    
	vec2 p = uv*5.+vec2(1,0);
    
    //mod(y, 2.) is a way to do even/odd
    //float dir = step(1.,mod(p.y,2.));
    // direction is -1 or 1
    //dir=(dir-.5)*2.;
    
    //vec2 ch = vec2(p.x, sin(p.y));
    
    // The distance field to the grid full of pseudo characters.
    float d = ChChars(p, flip);
    // The distance field for the corresponding shadow.
    float dSh = ChChars(p - vec2(1, -.8)*.1, flip);
    
    // Distance field shade value. Not to be confused with the shadow above. :)
    float dShade = max(1. - d*16., 0.)*.04;
    
    // Set the background
	vec3 col = bg_color;
    //vec3 col = vec3(.96, .92, .88);
   

    // Apply the distance field to the canvas. Just a mild shadow and icon outline,
    // followed by black or red characters.
    
    // Set the character color to something light.
    vec3 charCol = vec3(.9);
    // Using the individual character cell ID, "floor(p)," obtain a random number, then 
    // set the occasional character to red.
    //if(hash21(floor(p))>.9) charCol = vec3(1, .03, .01);

    // Shadow (offset distance field), light character outline, and color layers.
    //col = mix(col, vec3(0), (1. - smoothstep(0., .03, dSh - .06))*.25);
    col = mix(col, vec3(0.25), (1. - smoothstep(0., .02, d - .06))*.5);
    col = mix(col, charCol + dShade, 1. - smoothstep(0., .01, d - .04));
    
    
    // Just the field lines, for anyone interested.
    //col = vec3(1)*(clamp(cos(d*6.2831*8.) + .1, 0., 1.));
    
    /*
    // Show the grid border -- Kind of self explanatory, but the option's
    // there anyway. :)
    vec2 q = abs(fract(p) - .5);
    d = max(q.x, q.y) - .5 + .015;
    col = mix(col, vec3(0), smoothstep(0., .01, d + .02)*.8);
    col = mix(col, vec3(1), smoothstep(0., .005, d));
    */
    
    
    // Apply a tiny sprinkling of noise, just to break things up a little.
    //float ns = fbm(vec3(p, 1), 64.);//n3D(vec3(p, 1)*64.)*.57 + n3D(vec3(p, 1)*128.)*.28 + n3D(vec3(p, 1)*256.)*.15;
    //col *= ns*.25 + .8;
	return col;
}

float range(float a, float b, float v) {
	return step(a, v)*step(v, b);
}

vec2 mirror(vec2 uv) {
	//To get the mirror effect
    if (uv.y > 0.75) uv.y = 1.0 - uv.y;
	return uv;
}

void fragment() {
	// Place fragment code here.
	//ALBEDO = vec3(UV, 0.0);
	// everything below UV.y 0.5 is excluded 
	//step - everything under the limit returns 0
	//ALBEDO = mix(vec3(1.,0.,0.), vec3(0.,1.0, 0.), step(UV.x, 0.8));

	//front needs 0.48 offset to letters
	float v = range(0.5, 0.75, UV.y); //this range only covers the front itself, no back
	//v = v * range(0.005, 0.8, UV.x);
	vec3 text_col = makeChars(UV+vec2(0.0, 0.48)+offset, false, color.rgb);
	vec3 col = mix(vec3(0.2, 0.2, 0.2), text_col, v);
	
	//back
	v = step(0.75, UV.y);
	//fixes the side being text'ed
	v = v * 1.0-step(0.8, UV.x);
	//UV.x should be the same as on the front, so we only need to adjust Y
	// this grabs the same text as on the front
	text_col = makeChars(UV-vec2(0.0, -0.22)+offset, true, color.rgb);
	vec3 col2 = mix(col, text_col, v);
	//vec3 col2 = mix(col, makeChars(UV+vec2(0.0, 0.225)), v);
    ALBEDO = col2;

}
