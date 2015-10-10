//
//  WebSocketInterface.h
//  libwebsockets
//
//  Created by liwenfeng on 15/5/16.
//
//

#ifndef libwebsockets_WebSocketInterface_h
#define libwebsockets_WebSocketInterface_h

#include <string>
#include <vector>
#include "define.h"

namespace network
{
    class WebSocketInterface;
    //消息处理类
    class Delegate
    {
    public:
        Delegate(){}
        virtual ~Delegate() {}
        
        virtual void onOpen(WebSocketInterface* ws) = 0;
        virtual void onMessage(WebSocketInterface* ws, const Data& data) = 0;
        virtual void onClose(WebSocketInterface* ws) = 0;
        virtual void onError(WebSocketInterface* ws, const ErrorCode& error) = 0;
    };
    
    //接口类
    class WebSocketInterface
    {
    public:
        WebSocketInterface(){};
        virtual ~WebSocketInterface(){};
        
    public:
        static WebSocketInterface* createWebsocket();
        
        static void releaseWebsocket(WebSocketInterface* websocket);
        
        virtual bool init(const Delegate& delegate,
                          const std::string& url,
                          const std::vector<std::string>* protocols = nullptr) = 0;
        
        //发送文本消息
        virtual void send(const std::string& message) = 0;
        
        //发送二进制消息
        virtual void send(const unsigned char* binaryMsg, unsigned int len) = 0;
        
        virtual State getReadyState() = 0;
        
        //关闭websocket
        virtual void close() = 0;
    };
}
#endif
