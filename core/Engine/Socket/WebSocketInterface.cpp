//
//  WebSocketInterface.cpp
//  libwebsockets
//
//  Created by liwenfeng on 15/5/16.
//
//

#include "WebSocket.h"
#include "WebSocketInterface.h"

namespace network {
    
    WebSocketInterface* WebSocketInterface::createWebsocket()
    {
        return new WebSocket();
    }
    
    void WebSocketInterface::releaseWebsocket(WebSocketInterface* websocket)
    {
        if (websocket) {
            websocket->close();
            delete websocket;
        }
    }
}