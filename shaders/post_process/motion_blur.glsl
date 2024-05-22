#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform sampler2D color_texture;
layout(set = 0, binding = 1) uniform sampler2D depth_texture;
layout(set = 0, binding = 2) uniform sampler2D velocity_texture;

layout(rg8, set = 1, binding = 0) uniform image2D output_image;
layout(r8, set = 1, binding = 1) uniform image2D output_image_2;
layout(rgba32f, set = 1, binding = 2) uniform image2D output_image_3;

void main() {

    vec2 img_size = imageSize(output_image);
    vec2 uv = vec2(gl_GlobalInvocationID.xy)/vec2(img_size.xy);
    vec3 velocity = texture(velocity_texture, uv).rgb + vec3(0.5,0.5,0.5);
    vec3 depth = (texture(depth_texture, uv).rgb/8.0) + vec3(0.5,0.5,0.5);
    vec3 colour = texture(color_texture, uv).rgb;

    imageStore(output_image, ivec2(gl_GlobalInvocationID.xy), vec4(velocity,1.0));
    imageStore(output_image_2, ivec2(gl_GlobalInvocationID.xy), vec4(depth,1.0));
    imageStore(output_image_3, ivec2(gl_GlobalInvocationID.xy), vec4(colour,1.0));
}
