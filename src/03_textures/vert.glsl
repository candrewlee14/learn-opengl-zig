layout (location = 0) in vec3 aPos; // the position variable has attribute position 0
layout (location = 1) in vec3 aColor; // the color variable has attribute position 1)
layout (location = 2) in vec2 aTexCoord; // the texture variable has attribute position 2
  
out vec3 vertexColor; // specify a color output to the fragment shader
out vec2 TexCoord; // specify a texture coordinate output to the fragment shader

void main()
{
    gl_Position = vec4(aPos, 1.0);
    vertexColor = aColor;
    TexCoord = aTexCoord;
}
