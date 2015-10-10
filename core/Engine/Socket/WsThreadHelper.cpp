//
//  WsThreadHelper.cpp
//  libwebsockets
//
//  Created by liwenfeng on 15/5/16.
//
//

#include "WsThreadHelper.h"
#include "define.h"


namespace network {
    
    WsThreadHelper::WsThreadHelper()
    : _subThreadInstance(NULL)
    , _ws(NULL)
    , _needQuit(false)
    {
        _UIWsMessageQueue = new std::list<WsMessage*>();
        _subThreadWsMessageQueue = new std::list<WsMessage*>();
    }
    
    WsThreadHelper::~WsThreadHelper()
    {
        joinSubThread();
        CC_SAFE_DELETE(_subThreadInstance);
        delete _UIWsMessageQueue;
        delete _subThreadWsMessageQueue;
    }
    
    bool WsThreadHelper::createThread(const WebSocket& ws)
    {
        _ws = const_cast<WebSocket*>(&ws);
        
        _subThreadInstance = new std::thread(&WsThreadHelper::wsThreadEntryFunc, this);
        return true;
    }
    
    void WsThreadHelper::quitSubThread()
    {
        _needQuit = true;
    }
    
    void WsThreadHelper::wsThreadEntryFunc()
    {
        _ws->onSubThreadStarted();
        
        while (!_needQuit)
        {
            if (_ws->onSubThreadLoop())
            {
                break;
            }
        }
    }
    
    void WsThreadHelper::sendMessageToUIThread(WsMessage *msg)
    {
        if (_ws)
        {
            _ws->onUIThreadReceiveMessage(msg);
        }
        
        CC_SAFE_DELETE(msg);
    }
    
    void WsThreadHelper::sendMessageToSubThread(WsMessage *msg)
    {
        std::lock_guard<std::mutex> lk(_subThreadWsMessageQueueMutex);
        _subThreadWsMessageQueue->push_back(msg);
    }
    
    void WsThreadHelper::joinSubThread()
    {
        if (_subThreadInstance->joinable())
        {
            _subThreadInstance->join();
        }
    }
    
    void WsThreadHelper::update()
    {
        WsMessage *msg = nullptr;
        
        if (0 == _UIWsMessageQueue->size())
            return;
        
        _UIWsMessageQueueMutex.lock();
        
        if (0 == _UIWsMessageQueue->size())
        {
            _UIWsMessageQueueMutex.unlock();
            return;
        }
        
        msg = *(_UIWsMessageQueue->begin());
        _UIWsMessageQueue->pop_front();
        
        _UIWsMessageQueueMutex.unlock();
        
        if (_ws)
        {
            _ws->onUIThreadReceiveMessage(msg);
        }
        
        CC_SAFE_DELETE(msg);
    }
}