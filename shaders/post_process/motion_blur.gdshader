shader_type canvas_item;
//include ACES tonemap
#include "tonemap/aces.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D colour_texture;
uniform sampler2D depth_texture;
uniform sampler2D velocity_texture;
uniform mat4 INV_PROJECTION_MATRIX;

//note: theres tradeoffs to using each kind of texture
//screen_texture is ahead of the motion vectors by 1 frame but bloom works fine
//colour texture is in sync with the motion vectors but some effects like bloom dont work

vec3 pixelate(sampler2D img, vec2 uv, vec2 factor) {
	vec3 result;
	
	
	int x_passes = 4;
	int y_passes = 4;
	
	vec3 col = vec3(0.0);
	float dep = 0.0;
	
	for (int x=0; x < x_passes; x++) {
		for (int y=0; y < y_passes; y++) {
			
			vec2 ofs_ofs = -vec2(factor.x,factor.y)/4.0;
			vec2 ofs = vec2(factor.x*(float(x)/float(x_passes)),factor.y*(float(y)/float(y_passes)));
			vec2 new_uv = ((round(uv*factor)+(ofs))/factor);
			
			col += texture(img,new_uv).rgb;
			dep += texture(depth_texture,new_uv).r;
		}
	}
	
	col = col / float(x_passes*y_passes);
	vec3 colourtex = texture(velocity_texture,uv).rgb;
	dep = dep / float(x_passes*y_passes);
	float depth = texture(depth_texture, uv).r;
	
	float diff = clamp(distance(depth,dep),0.0,1.0);
	
	//result = mix(colourtex,col,vec3(diff));
	result = col;
	return result;
}

vec3 average(sampler2D img, vec2 uv, vec2 fac) {
	vec3 result;
	
	int passes = 8;
	int x_passes = 4;
	int y_passes = 4;
	
	vec3 col = vec3(0.0);
	float dep = 0.0;
	for (int i=0; i < passes; i++) {
		
		vec2 factor = fac / float(i);
		
		for (int x=0; x < x_passes; x++) {
			for (int y=0; y < y_passes; y++) {
				
				vec2 ofs = vec2(factor.x*(float(x/x_passes)),factor.y*(float(y/y_passes)));
				vec2 new_uv = ((round(uv*factor)+(ofs))/factor);
				
				col += texture(img,new_uv).rgb;
				dep += texture(depth_texture,new_uv).r;
			}
		}
	}
	
	
	col = col / float(x_passes*y_passes*passes);
	vec3 colourtex = texture(velocity_texture,uv).rgb;
	dep = dep / float(x_passes*y_passes);
	float depth = texture(depth_texture, uv).r;
	
	float diff = clamp(distance(depth,dep),0.0,1.0);
	
	//result = mix(colourtex,col,vec3(diff));
	result = col;
	return result;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	float k = 15.0;
	vec2 factor = vec2(textureSize(screen_texture,0))/k;

	int samples = 32;

    float intensity = 1.0;
	//float intensity = 0.05;
    //vec3 velocity = texture(velocity_texture, SCREEN_UV).rgb - vec3(0.5);
	//vec3 velocity2 = texture(velocity_texture, SCREEN_UV).rgb - vec3(0.5);
	
	vec3 velocity = average(velocity_texture,SCREEN_UV,factor).rgb - vec3(0.5);
    vec2 ofs = SCREEN_UV;
    vec2 ofs2 = SCREEN_UV;
	
	vec3 colour = vec3(0.0);

    for (int i=0; i < samples; i++) {
		velocity = average(velocity_texture,ofs,factor).rgb - vec3(0.5);
        float indf = float(i);
		float sampf = float(samples);
		vec3 blur1 = aces(texture(colour_texture, ofs).rgb);
		vec3 blur2 = aces(texture(colour_texture, ofs2).rgb);
        ofs = SCREEN_UV + (velocity.rg*intensity*((indf)/(sampf-1.0)-0.5));
        ofs2 = SCREEN_UV - (velocity.rg*intensity*((indf)/(sampf-1.0)-0.5));

		



		colour = (colour) + 0.5*(blur1+blur2);
    }
	COLOR = vec4((colour/float(samples)),1.0);
	//COLOR = vec4(velocity,1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
