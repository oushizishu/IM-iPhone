//
//  WsThreadHelper.h
//  libwebsockets
//
//  Created by liwenfeng on 15/5/16.
//
//

#ifndef libwebsockets_WsThreadHelper_h
#define libwebsockets_WsThreadHelper_h

#include "WebSocket.h"
#include <list>
#include <mutex>
#include <thread>

namespace network {
    
    class WsThreadHelper
    {
    public:
        WsThreadHelper();
        ~WsThreadHelper();
        friend class WebSocket;
        
        bool createThread(const WebSocket& ws);
        
        void quitSubThread();
        
        virtual void update();
        
        void sendMessageToUIThread(WsMessage *msg);
        
        void sendMessageToSubThread(WsMessage *msg);
        
        void joinSubThread();
        
    protected:
        void wsThreadEntryFunc();
        
    private:
        std::list<WsMessage*>* _UIWsMessageQueue;
        std::list<WsMessage*>* _subThreadWsMessageQueue;
        
        std::mutex   _UIWsMessageQueueMutex;
        std::mutex   _subThreadWsMessageQueueMutex;
        std::thread* _subThreadInstance;
        WebSocket* _ws;
        bool _needQuit;
    };
}

#endif
