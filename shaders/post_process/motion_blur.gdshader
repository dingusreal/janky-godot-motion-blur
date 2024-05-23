shader_type canvas_item;
//include ACES tonemap
#include "tonemap/aces.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D colour_texture;
uniform sampler2D depth_texture;
uniform sampler2D velocity_texture;
uniform sampler2D prev_velocity_texture;
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

			col += texture(img,new_uv).rgb * (1.0-sin(length(ofs)));
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

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 average(sampler2D img, vec2 uv, vec2 fac) {
	vec3 result;

	int passes = 8;
	int x_passes = 4;
	int y_passes = 4;

	vec3 col = vec3(0.0);
	float dep = 0.0;
	for (int i=0; i < passes; i++) {

		vec2 factor = (fac+float(i)) * (clamp(2.0*rand(uv*TIME),0.5,1.5));

		for (int x=0; x < x_passes; x++) {
			for (int y=0; y < y_passes; y++) {

				vec2 ofs = vec2(factor.x*(float(x/x_passes)),factor.y*(float(y/y_passes)));
				vec2 ofsn = vec2(factor.x*(float(x/x_passes)),factor.y*(float(clamp(y-1,0,y_passes)/y_passes)));
				vec2 ofss = vec2(factor.x*(float(x/x_passes)),factor.y*(float(clamp(y+1,0,y_passes)/y_passes)));
				vec2 ofse = vec2(factor.x*(float(clamp(x+1,0,x_passes)/x_passes)),factor.y*(float(y/y_passes)));
				vec2 ofsw = vec2(factor.x*(float(clamp(x-1,0,x_passes)/x_passes)),factor.y*(float(y/y_passes)));



				vec2 new_uv = ((round(uv*factor)+(ofs))/factor);
				vec2 new_uv1 = ((round(uv*factor)+(ofsn))/factor);
				vec2 new_uv2 = ((round(uv*factor)+(ofss))/factor);
				vec2 new_uv3 = ((round(uv*factor)+(ofse))/factor);
				vec2 new_uv4 = ((round(uv*factor)+(ofsw))/factor);

				vec3 res = max(texture(img,new_uv).rgb,max(max(texture(img,new_uv1).rgb,texture(img,new_uv2).rgb),max(texture(img,new_uv3).rgb,texture(img,new_uv4).rgb)));
				col += res;
				dep += texture(depth_texture,new_uv).r;
			}
		}
	}


	col = col / float(x_passes*y_passes*passes);
	vec3 colourtex = texture(velocity_texture,uv).rgb;
	dep = dep / float(x_passes*y_passes);
	float depth = texture(depth_texture, uv).r;

	float diff = clamp(distance(depth,dep),0.0,0.1);

	//result = mix(col,colourtex,vec3(sin(diff)));
	result = col;
	return result;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	float k = 8.0;

	int samples = 12;

    float intensity = 1.0/float(samples);
	//float intensity = 0.05;
    //vec3 velocity = texture(velocity_texture, SCREEN_UV).rgb - vec3(0.5);
	//vec3 velocity2 = texture(velocity_texture, SCREEN_UV).rgb - vec3(0.5);

	vec3 velocity = average(velocity_texture,SCREEN_UV,vec2(k)).rgb - vec3(0.5);
	//vec3 prev_velocity = average(prev_velocity_texture,SCREEN_UV,vec2(k)).rgb - vec3(1.0);
	//velocity = average(velocity_texture,SCREEN_UV,velocity.rg).rgb - vec3(0.5);
	//velocity = velocity+(prev_velocity-velocity) * 0.25;
	//velocity *= 2.0;
    vec2 ofs1 = vec2(0.0);
	vec2 ofs2 = vec2(0.0);


	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 colour = vec3(0.0);

    for (int i=0; i < samples; i++) {
		float indf = float(i);
		float sampf = float(samples);


		//velocity = average(velocity_texture,ofs,vec2(k)).rgb - vec3(0.5);
        intensity = 16.0/float(samples);
		vec3 blur1 = (texture(colour_texture, SCREEN_UV+ofs1).rgb);
		vec3 blur2 = (texture(colour_texture, SCREEN_UV+ofs2).rgb);


		vec3 blur = aces((blur1+blur2)/2.0);

        ofs1 = ((velocity.rg*intensity)*((indf)/(sampf-1.0)-0.5))*clamp(rand(SCREEN_UV+vec2(TIME+0.000)),0.25,1.0);
		ofs2 = ((velocity.rg*intensity)*((indf)/(sampf-1.0)-0.5))*clamp(rand(SCREEN_UV+vec2(TIME+0.001)),0.25,1.0);








		colour = (colour) + (blur);
    }


	COLOR = vec4((colour/float(samples)),1.0);



	//COLOR = vec4(velocity,1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
