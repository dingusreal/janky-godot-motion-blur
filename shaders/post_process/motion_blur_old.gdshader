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

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float depth = texture(depth_texture,SCREEN_UV).r;
	vec4 H = vec4(SCREEN_UV.x*2.0-1.0, (1.0-SCREEN_UV.y) * 2.0 - 1.0, depth, 1.0);
	vec4 D = H * INV_PROJECTION_MATRIX;

	float S = 15.0;
	float k = 20.0;

	int samples = 16;

    float intensity = 0.4;
	//float intensity = 0.05;
    vec3 velocity = texture(velocity_texture, SCREEN_UV).rgb - vec3(0.5);
	vec3 velocity2 = texture(velocity_texture, SCREEN_UV).rgb - vec3(0.5);
    vec2 ofs = SCREEN_UV - (velocity.rg*intensity);
    vec2 ofs2 = SCREEN_UV + (velocity2.rg*intensity);
	vec3 colour = texture(colour_texture, SCREEN_UV).rgb;

    for (int i=0; i < samples; i++) {
        float indf = float(i);
		float sampf = float(samples);
        ofs = SCREEN_UV - (velocity.rg*intensity*((indf)/(sampf-1.0)-0.5));
        ofs2 = SCREEN_UV + (velocity2.rg*intensity*((indf)/(sampf-1.0)-0.5));

		vec3 blur1 = texture(colour_texture, ofs).rgb;
		vec3 blur2 = texture(colour_texture, ofs2).rgb;



		colour = (colour) + (((sampf-indf)/sampf)*(blur1+blur2));
    }
	COLOR = vec4(aces(colour/float(samples)),1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
