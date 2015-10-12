//
//  WebSocket.h
//  libwebsockets
//
//  Created by liwenfeng on 15/5/16.
//
//

#ifndef libwebsockets_WebSocket_h
#define libwebsockets_WebSocket_h

#include <string>
#include <vector>

#include "define.h"
#include "libwebsockets.h"
#include "WebSocketInterface.h"

struct libwebsocket;
struct libwebsocket_context;
struct libwebsocket_protocols;

namespace network {
    
    class WsThreadHelper;
    
    class WebSocket :
        public WebSocketInterface
    {
    public:
        WebSocket();
        virtual ~WebSocket();
        
    public:
        virtual bool init(const Delegate& delegate,const std::string& url,const std::vector<std::string>* protocols = nullptr);
        
        virtual void send(const std::string& message);
        
        virtual void send(const unsigned char* binaryMsg, unsigned int len);
        
        virtual void close();
        
        State getReadyState();
        
    private:
        bool update();
        void onSubThreadStarted();
        int  onSubThreadLoop();
        void onSubThreadEnded();
        void onUIThreadReceiveMessage(WsMessage* msg);
        
        friend class WebSocketCallbackWrapper;
        int onSocketCallback(struct libwebsocket_context *ctx,
                             struct libwebsocket *wsi,
                             int reason,
                             void *user, void *in, ssize_t len);
    private:
        State        _readyState;
        std::string  _host;
        unsigned int _port;
        std::string  _path;
        
        ssize_t _pendingFrameDataLen;
        ssize_t _currentDataLen;
        char *_currentData;
        
        friend class WsThreadHelper;
        WsThreadHelper* _wsHelper;
        
        struct libwebsocket*         _wsInstance;
        struct libwebsocket_context* _wsContext;
        Delegate* _delegate;
        int _SSLConnection;
        struct libwebsocket_protocols* _wsProtocols;
        
        ErrorCode err;
    };
}

#endif
