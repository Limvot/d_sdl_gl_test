import std.stdio;
import std.string;

//OpenGL and SDL
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

import networkclient;

immutable char* WindowTitle = "Hello Derelict - SDl2, OpenGL!";
immutable uint windowX = 128;
immutable uint windowY = 128;


void main() {
    //Loading OpenGL versions 1.0 and 1.1
    DerelictGL3.load();
    
    //Load SDL2
    DerelictSDL2.load();

    //Load SDL_net
    DerelictSDL2Net.load();

    // New way to do networking.
    string host = "127.0.0.1";
    SDLNet_Initialize(host, 1234);

    clearbuffer(); // Should already be clear, but just in case...
    writestring("hello!");
    sendmessage(getSocket());


    //Create a contexted with SDL 2
    SDL_Window *window;
    SDL_GLContext glcontext;
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        writeln("SDL2 failed to init: ", SDL_GetError());
        return;
    }
    //Ok, we want an OpenGL 3.3 context
    version (OSX) {
        //Mac needs us to specifically ask for a core profile and OpenGL version 3.2
        //If the Mac supports it, we'll still get access to 3.3 (and 4.1, but we're not using that)
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    } else {
        //Otherwise, just ask 3.3 directly
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    }
    //Double Buffering
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    /* // Attempted fullscreen, unsuccessful
    SDL_VideoInfo* info = SDL_GetVideoInfo();
    int bpp = *(*info.vfmt).BitsPerPixel;

    int flags = SDL_OPENGL | SDL_FULLSCREEN;

    if (SDL_SetVideoMode(width, height, bpp, flags) == 0){
        writeln("SDL SetVideoMode failure: ", SDL_GetError());
        return;
    }
    */

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

    bool running = true;

    
    bool left = false;
    bool right = false;
    bool up = false;
    bool down = false;

    while(running){
        SDL_Event event;
        handleInput(&event, &left, &right, &up, &down, &running);

        SDL_Delay(1000/60);
    }

    //Finish up and exit
    SDL_GL_DeleteContext(glcontext);
    SDL_DestroyWindow(window);
    SDLNet_TCP_Close(socket);
    SDLNet_Quit();
    SDL_Quit();
}

void handleInput(SDL_Event *event, bool *left, bool *right, bool *up, bool *down, bool *running){
    while( SDL_PollEvent( event ) ){
            /* We are only worried about SDL_KEYDOWN and SDL_KEYUP events */
            switch( event.type ){
              case SDL_KEYDOWN:
                switch(event.key.keysym.sym){
                    case SDLK_LEFT:
                        writeln("LEFT DETECTED");
                        *left = true;
                        break;
                    case SDLK_RIGHT:
                        writeln("RIGHT DETECTED");
                        *right = true;
                        break;
                    case SDLK_UP:
                        writeln("UP DETECTED");
                        *up = true;
                        break;
                    case SDLK_DOWN:
                        writeln("DOWN DETECTED");
                        *down = true;
                        break;
                    case SDLK_RETURN:
                        // Send a message to the server.
                        writestring("howdy");
                        sendmessage(getSocket());
                        break;
                    case SDLK_ESCAPE:
                        *running = false;
                        break;
                    default:
                        break;
                }
                break;

              case SDL_KEYUP:
                switch(event.key.keysym.sym){
                    case SDLK_LEFT:
                        *left = false;
                        break;
                    case SDLK_RIGHT:
                        *right = false;
                        break;
                    case SDLK_UP:
                        *up = false;
                        break;
                    case SDLK_DOWN:
                        *down = false;
                        break;
                    case SDLK_ESCAPE:
                        *running = false;
                        break;
                    case SDLK_RETURN:
                        break;
                    default:
                        writeln("Key release detected");
                        break;
                }
                
                break;

              default:
                break;
            }
        }
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
    debug writeln("Compiling Vertex Shader");
    const GLchar* vertCStrPtr = vertShaderSource.toStringz();
    debug writeln("Vertex Shader: ", vertShaderSource); 
    glShaderSource(vertShaderID, 1, &vertCStrPtr, cast(GLint*)null);
    glCompileShader(vertShaderID);

    glGetShaderiv(vertShaderID, GL_COMPILE_STATUS, &result);
    glGetShaderiv(vertShaderID, GL_INFO_LOG_LENGTH, &logLength);
    char[] vertShaderLog = new char[logLength];
    glGetShaderInfoLog(vertShaderID, logLength, cast(GLsizei*)null, vertShaderLog.ptr);
    debug writeln("Vertex Shader Info Log: ", vertShaderLog);

    //Compile Fragment Shader
    debug writeln("Compiling Fragment Shader");
    const GLchar* fragCStrPtr = fragShaderSource.toStringz();
    debug writeln("Fragment Shader: ", fragShaderSource); 
    glShaderSource(fragShaderID, 1, &fragCStrPtr, cast(GLint*)null);
    glCompileShader(fragShaderID);

    glGetShaderiv(fragShaderID, GL_COMPILE_STATUS, &result);
    glGetShaderiv(vertShaderID, GL_INFO_LOG_LENGTH, &logLength);
    char[] fragShaderLog = new char[logLength];
    glGetShaderInfoLog(vertShaderID, logLength, cast(GLsizei*)null, fragShaderLog.ptr);
    debug writeln("Fragment Shader Info Log: ", fragShaderLog);
    
    //Link them
    debug writeln("Linking Program");
    glAttachShader(programID, vertShaderID);
    glAttachShader(programID, fragShaderID);
    glLinkProgram(programID);

    glGetProgramiv(programID, GL_LINK_STATUS, &result);
    glGetProgramiv(programID, GL_INFO_LOG_LENGTH, &logLength);
    char[] programLog = new char[logLength];
    glGetShaderInfoLog(vertShaderID, logLength, cast(GLsizei*)null, programLog.ptr);
    debug writeln("Program Info Log: ", programLog);

    glDeleteShader(vertShaderID);
    glDeleteShader(fragShaderID);

    return programID;
}
