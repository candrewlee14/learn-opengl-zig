layout (location = 0) in vec3 aPos; // the position variable has attribute position 0
layout (location = 1) in vec2 aTexCoord; // the texture variable has attribute position 2
  
uniform mat4 transform;

out vec2 TexCoord; // specify a texture coordinate output to the fragment shader

void main()
{
    gl_Position = transform * vec4(aPos, 1.0f);
    TexCoord = aTexCoord;
}
