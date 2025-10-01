shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {	
	vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float f = c.r + c.g + c.b / 3.0;
	
	vec3 v = vec3(f * c.r / 2.0,f * c.g / 2.0,f * c.b / 2.0);
	COLOR.rgb = v;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
