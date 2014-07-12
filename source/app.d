import std.stdio;
import std.string;

//OpenGL and SDL
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

immutable char* WindowTitle = "Hello Derelict - SDl2!";
immutable uint windowX = 512;
immutable uint windowY = 512;

void main() {
    //Loading OpenGL versions 1.0 and 1.1
    DerelictGL3.load();
    
    //Load SDL2
    DerelictSDL2.load();

    //Create a contexted with SDL 2
    SDL_Window *window;
    SDL_GLContext glcontext;
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        writeln("SDL2 failed to init: ", SDL_GetError());
        return;
    }
    //Ok, we want an OpenGL 3.2 context
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);

    //Double Buffering
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    //Create the window
    window = SDL_CreateWindow(WindowTitle, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                windowX, windowY, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
    if (!window) {
        writeln("Failed to create SDL window: ", SDL_GetError());
        return;
    }

    //Create the OpenGL context
    SDL_ClearError();
    glcontext = SDL_GL_CreateContext(window);
    const char *error = SDL_GetError();
    if (*error != '\0') {
        printf("SDL Error creating OpenGL context: %s", error);
        SDL_ClearError();
        return;
    }

    //Load OpenGL versions 1.2+ and all supported ARB and EXT extensions
    DerelictGL3.reload();

    //Ok, let's make something cool
    GLuint vArrayID;
    glGenVertexArrays(1, &vArrayID);
    glBindVertexArray(vArrayID);
    
    immutable GLfloat[9] vBufferData = [
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0,
        0.0, 1.0, 0.0,
    ];

    GLuint vBuffer;
    glGenBuffers(1, &vBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
    glBufferData(GL_ARRAY_BUFFER, vBufferData.sizeof, cast(void*)vBufferData, GL_STATIC_DRAW);
    
    //Load shaders
    GLuint shaderProgramID = makeShaders(simpleVertShaderSource, simpleFragShaderSource);

    //Draw
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //Use shader
    glUseProgram(shaderProgramID);
    
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
    //attribute 0, size, type, normalized, stride, array buffer offset
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(void*)0);
    //Start from vertex 0, 3 total
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glDisableVertexAttribArray(0);
    
    SDL_GL_SwapWindow(window); 
    
    SDL_Delay(2000);

    //Finish up and exit
    SDL_GL_DeleteContext(glcontext);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

string simpleVertShaderSource = "
#version 330 core
layout (location = 0) in vec3 vertexPos_modelspace;

void main() {
    gl_Position.xyz = vertexPos_modelspace;
    gl_Position.w = 1.0;
} 
";

string simpleFragShaderSource = "
#version 330 core
out vec3 color;

void main() {
    color = vec3(1,0,0);
} 
";

GLuint makeShaders(string vertShaderSource, string fragShaderSource) {
    GLuint vertShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint fragShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    GLuint programID = glCreateProgram();
    GLint result = GL_FALSE;
    int logLength;

    //Compile Vertex Shader
    writeln("Compiling Vertex Shader");
    const GLchar* vertCStrPtr = vertShaderSource.toStringz();
    debug writeln("Vertex Shader: ", vertShaderSource); 
    glShaderSource(vertShaderID, 1, &vertCStrPtr, cast(GLint*)null);
    glCompileShader(vertShaderID);

    glGetShaderiv(vertShaderID, GL_COMPILE_STATUS, &result);
    glGetShaderiv(vertShaderID, GL_INFO_LOG_LENGTH, &logLength);
    char[] vertShaderLog = new char[logLength];
    glGetShaderInfoLog(vertShaderID, logLength, cast(GLsizei*)null, vertShaderLog.ptr);
    writeln("Vertex Shader Info Log: ", vertShaderLog);

    //Compile Fragment Shader
    writeln("Compiling Fragment Shader");
    const GLchar* fragCStrPtr = fragShaderSource.toStringz();
    debug writeln("Fragment Shader: ", fragShaderSource); 
    glShaderSource(fragShaderID, 1, &fragCStrPtr, cast(GLint*)null);
    glCompileShader(fragShaderID);

    glGetShaderiv(fragShaderID, GL_COMPILE_STATUS, &result);
    glGetShaderiv(vertShaderID, GL_INFO_LOG_LENGTH, &logLength);
    char[] fragShaderLog = new char[logLength];
    glGetShaderInfoLog(vertShaderID, logLength, cast(GLsizei*)null, fragShaderLog.ptr);
    writeln("Fragment Shader Info Log: ", fragShaderLog);
    
    //Link them
    writeln("Linking Program");
    glAttachShader(programID, vertShaderID);
    glAttachShader(programID, fragShaderID);
    glLinkProgram(programID);

    glGetProgramiv(programID, GL_LINK_STATUS, &result);
    glGetProgramiv(programID, GL_INFO_LOG_LENGTH, &logLength);
    char[] programLog = new char[logLength];
    glGetShaderInfoLog(vertShaderID, logLength, cast(GLsizei*)null, programLog.ptr);
    writeln("Program Info Log: ", programLog);

    glDeleteShader(vertShaderID);
    glDeleteShader(fragShaderID);

    return programID;
}
