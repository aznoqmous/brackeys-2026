shader_type canvas_item;
uniform vec3 input_color:source_color;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 pos = SCREEN_UV / SCREEN_PIXEL_SIZE;
	float grid_size = 1.0 / 20.0;
	float value = (sin(pos.x * grid_size + TIME) + sin(pos.y * grid_size + TIME)) * 10000.0;
	value = min(1.0, value);
	value = max(0.0, value);
	float counter_value = 1.0 - value;
	// Called for every pixel the material is visible on.
	vec3 color = vec3(value * input_color) + vec3(counter_value * input_color) * 1.05;
	color *= vec3(1.0 - SCREEN_UV.y * 0.2);
	COLOR = vec4(color, 1.0);
	//COLOR = vec4(input_color, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
