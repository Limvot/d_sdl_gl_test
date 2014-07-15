import std.stdio;
import std.string;

import derelict.sdl2.net;

TCPsocket socket;
byte buffer[512];
int iBuffer;
IPaddress ip;

void function(string) func;

bool SDLNet_Initialize(const string host, ushort port){
	if (SDLNet_Init() < 0) {
        writeln("SDLNet Init failure: ", SDLNet_GetError());
        return false;
    }
	// Create a socket set to hold our sockets
    SDLNet_SocketSet socketSet = SDLNet_AllocSocketSet(1);

    string hostN = host;
    const char* hostName = (hostN).toStringz();

    if (SDLNet_ResolveHost(&ip, hostName, port) < 0) {
        writeln("SDLNet ResolveHost failure: ", SDLNet_GetError());
        return false;
    }
    socket = SDLNet_TCP_Open(&ip);
    if (!socket) {
        writeln("SDLNet TCP_Open failure: ", SDLNet_GetError());
        writeln("Could not connect to server. ");
        return false;
    }

    // Add our socket to our socket set
    SDLNet_TCP_AddSocket(socketSet, socket);

    iBuffer = 0;

    return true;

    /*
    // Check for stuff coming in, wait for half a second
    SDLNet_CheckSockets(socketSet, 500);

    buffer = "hello";
    int len = 5;

    // Send a message to the server.
    writeln("Sending a message to the server.");
    int sent = SDLNet_TCP_Send(socket, cast(void*)buffer, len);
    if (sent < len)
        writeln("Failed to send.");
    else
    	writeln("Sent!");
    */
}

void writestring(string s){
	for (int i = 0; i < s.length; i++){
		buffer[iBuffer] = s[i];
		iBuffer++;
	}
}

void writebyte(byte b){
	buffer[iBuffer] = b;
	iBuffer++;
}

void clearbuffer(){
	for (int i = 0; i < iBuffer; i++){
		buffer[i] = 0;
	}
	iBuffer = 0;
}

void sendmessage(TCPsocket socket){
	sendmessage(socket, true);
}

void sendmessage(TCPsocket socket, bool clear){
	int sent = SDLNet_TCP_Send(socket, cast(void*)buffer, iBuffer);
    if (sent < iBuffer)
        writeln("Failed to send.");
    if (clear)
    	clearbuffer();
}

TCPsocket getSocket(){
	return socket;
}

byte[] getBuffer(){
	return buffer;
}

IPaddress getIP(){
	return ip;
}