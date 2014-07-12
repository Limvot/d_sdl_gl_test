import std.stdio;

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
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);

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
    glcontext = SDL_GL_CreateContext(window);

    //Load OpenGL versions 1.2+ and all supported ARB and EXT extensions
    DerelictGL3.reload();

    //Ok, let's make something cool
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    SDL_GL_SwapWindow(window);
    SDL_Delay(2000);

    glClearColor(0.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    SDL_GL_SwapWindow(window);
    SDL_Delay(2000);
    
    glClearColor(0.0, 0.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    SDL_GL_SwapWindow(window);
    SDL_Delay(2000);
    
    //Finish up and exit
    SDL_GL_DeleteContext(glcontext);
    SDL_DestroyWindow(window);
    SDL_Quit();
}
