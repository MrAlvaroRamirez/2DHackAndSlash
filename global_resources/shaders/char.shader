shader_type canvas_item;

uniform vec4 new:hint_color;

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);

    if (current_pixel.a > float(0))
        COLOR = current_pixel - (current_pixel * new.a) + new;
    else
        COLOR = current_pixel;
}