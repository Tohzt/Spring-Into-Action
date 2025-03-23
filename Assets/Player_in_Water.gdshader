shader_type canvas_item;

uniform float cutoff_height = 0.85;  // Adjust this value to control where the cutoff happens (0.0 to 1.0)

void fragment() {
	// Get the original color from the texture
	vec4 color = texture(TEXTURE, UV);
	
	// Make bottom portion invisible
	if (UV.y > cutoff_height) {
		color.a = 0.0;
	}
	
	COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
