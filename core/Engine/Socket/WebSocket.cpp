//
//  WebSocket.cpp
//  libwebsockets
//
//  Created by liwenfeng on 15/5/16.
//
//

#include "WebSocket.h"
#include "WsThreadHelper.h"

#include <thread>
#include <mutex>
#include <queue>
#include <list>
#include <signal.h>
#include <errno.h>
#include <stdlib.h>

#ifdef ANDROID
#include "../jni/jni_helpers.h"
#endif

namespace network {
    
    class WebSocketCallbackWrapper
    {
    public:
        
        static int onSocketCallback(struct libwebsocket_context *ctx,
                                    struct libwebsocket *wsi,
                                    enum libwebsocket_callback_reasons reason,
                                    void *user, void *in, size_t len)
        {
            WebSocket* wsInstance = (WebSocket*)libwebsocket_context_user(ctx);
            if (wsInstance)
            {
                return wsInstance->onSocketCallback(ctx, wsi, reason, user, in, len);
            }
            return 0;
        }
    };
    
    WebSocket::WebSocket()
    : _readyState(State::CONNECTING)
    , _port(80)
    , _pendingFrameDataLen(0)
    , _currentDataLen(0)
    , _currentData(NULL)
    , _wsHelper(NULL)
    , _wsInstance(NULL)
    , _wsContext(NULL)
    , _delegate(NULL)
    , _SSLConnection(0)
    , _wsProtocols(NULL)
    ,err(ErrorCode::CONNECTION_FAILURE)
    {
    }
    
    WebSocket::~WebSocket()
    {
        close();
        
        if (_wsHelper) {
            _wsHelper->joinSubThread();
            CC_SAFE_DELETE(_wsHelper);
        }
        
        
        for (int i = 0; _wsProtocols[i].callback != nullptr; ++i)
        {
            CC_SAFE_DELETE_ARRAY(_wsProtocols[i].name);
        }
        CC_SAFE_DELETE_ARRAY(_wsProtocols);

#ifdef ANDROID
        LOG("WebSocket::~WebSocket, client is destroyed !");
#endif
    }
    
    bool WebSocket::update()
    {
        if (_wsHelper) {
            _wsHelper->update();
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
            return 0;
        }
        
        return 1;
    }
    
    bool WebSocket::init(const Delegate& delegate,
                         const std::string& url,
                         const std::vector<std::string>* protocols)
    {
        bool ret = false;
        bool useSSL = false;
        std::string host = url;
        size_t pos = 0;
        int port = 80;
        
        _delegate = const_cast<Delegate*>(&delegate);
        
        pos = host.find("ws://");
        if (pos == 0) host.erase(0,5);
        
        pos = host.find("wss://");
        if (pos == 0)
        {
            host.erase(0,6);
            useSSL = true;
        }
        
        pos = host.find(":");
        if (pos != std::string::npos) port = atoi(host.substr(pos+1, host.size()).c_str());
        
        pos = host.find("/", 0);
        std::string path = "/";
        if (pos != std::string::npos) path += host.substr(pos + 1, host.size());
        
        pos = host.find(":");
        if(pos != std::string::npos){
            host.erase(pos, host.size());
        }else if((pos = host.find("/")) != std::string::npos) {
            host.erase(pos, host.size());
        }
        
        _host = host;
        _port = port;
        _path = path;
        _SSLConnection = useSSL ? 1 : 0;
        
        size_t protocolCount = 0;
        if (protocols && protocols->size() > 0)
        {
            protocolCount = protocols->size();
        }
        else
        {
            protocolCount = 1;
        }
        
        _wsProtocols = new libwebsocket_protocols[protocolCount+1];
        memset(_wsProtocols, 0, sizeof(libwebsocket_protocols)*(protocolCount+1));
        if (!_wsProtocols) {
            return  ret;
        }
        if (protocols && protocols->size() > 0)
        {
            int i = 0;
            for (std::vector<std::string>::const_iterator iter = protocols->begin(); iter != protocols->end(); ++iter, ++i)
            {
                char* name = new char[(*iter).length()+1];
                strcpy(name, (*iter).c_str());
                _wsProtocols[i].name = name;
                _wsProtocols[i].callback = WebSocketCallbackWrapper::onSocketCallback;
            }
        }
        else
        {
            char* name = new char[20];
            strcpy(name, "default-protocol");
            _wsProtocols[0].name = name;
            _wsProtocols[0].callback = WebSocketCallbackWrapper::onSocketCallback;
        }
        
        // WebSocket thread needs to be invoked at the end of this method.
        _wsHelper = new (std::nothrow) WsThreadHelper();
        ret = _wsHelper->createThread(*this);

#ifdef ANDROID
        LOG("WebSocket::init, client host = %s",url.c_str());
#endif

        return ret;
    }
    
    
    void WebSocket::send(const std::string &message)
    {
        if (_readyState == State::OPEN)
        {
            WsMessage* msg = new (std::nothrow) WsMessage();
            msg->what = WS_MSG_TO_SUBTRHEAD_SENDING_STRING;
            Data* data = new (std::nothrow) Data();
            data->bytes = new char[message.length()+1];
            strcpy(data->bytes, message.c_str());
            data->len = static_cast<ssize_t>(message.length());
            msg->obj = data;
            _wsHelper->sendMessageToSubThread(msg);
        }
    }
    
    void WebSocket::send(const unsigned char* binaryMsg, unsigned int len)
    {
        if (_readyState == State::OPEN)
        {
            WsMessage* msg = new (std::nothrow) WsMessage();
            msg->what = WS_MSG_TO_SUBTRHEAD_SENDING_BINARY;
            Data* data = new (std::nothrow) Data();
            data->bytes = new char[len];
            memcpy((void*)data->bytes, (void*)binaryMsg, len);
            data->len = len;
            msg->obj = data;
            _wsHelper->sendMessageToSubThread(msg);
        }
    }
    
    void WebSocket::close()
    {
        if (_readyState == State::CLOSING || _readyState == State::CLOSED)
        {
            return;
        }
        
        _readyState = State::CLOSED;
        
        //等待子线程退出
        if (_wsHelper) {
            _wsHelper->joinSubThread();
        }
    }
    
    State WebSocket::getReadyState()
    {
        return _readyState;
    }
    
    void WebSocket::onSubThreadStarted()
    {
        struct lws_context_creation_info info;
        memset(&info, 0, sizeof info);
        
        /*
         * create the websocket context.  This tracks open connections and
         * knows how to route any traffic and which protocol version to use,
         * and if each connection is client or server side.
         *
         * For this client-only demo, we tell it to not listen on any port.
         */
        
        info.port = CONTEXT_PORT_NO_LISTEN;
        info.protocols = _wsProtocols;
#ifndef LWS_NO_EXTENSIONS
        info.extensions = libwebsocket_get_internal_extensions();
#endif
        info.gid = -1;
        info.uid = -1;
        info.user = (void*)this;    //**
        
        //添加tcp keeplive机制
        info.ka_time = 4000;
        info.ka_interval = 500;
        info.ka_probes = 2;
        
//        lws_set_log_level(LLL_ERR |LLL_WARN |LLL_NOTICE|LLL_INFO|LLL_DEBUG|LLL_PARSER,nullptr);
        _wsContext = libwebsocket_create_context(&info);
        
        if(nullptr != _wsContext)
        {
//            _readyState = State::CONNECTING;
            std::string name;
            for (int i = 0; _wsProtocols[i].callback != nullptr; ++i)
            {
                name += (_wsProtocols[i].name);
                
                if (_wsProtocols[i+1].callback != nullptr) name += ", ";
            }
            
            _wsInstance = libwebsocket_client_connect(_wsContext, _host.c_str(), _port, _SSLConnection,
                                                      _path.c_str(), _host.c_str(), _host.c_str(),
                                                      name.c_str(), -1);
            
            if(nullptr == _wsInstance) {
                _readyState = State::CLOSING;
            }
        }
    }
    
    int WebSocket::onSubThreadLoop()
    {
        if (_readyState == State::CLOSED || _readyState == State::CLOSING)
        {
            // close all active connections
            libwebsocket_context_destroy(_wsContext);
            
            return 1;   //this will lead subthread to exit
        }
        
        if (_wsContext && _readyState != State::CLOSED && _readyState != State::CLOSING)
        {
            libwebsocket_service(_wsContext, 0);
        }
        
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        
        return 0;
    }
    
    void WebSocket::onSubThreadEnded()
    {
        
    }
    
    void WebSocket::onUIThreadReceiveMessage(WsMessage *msg)
    {
        switch (msg->what)
        {
            case WS_MSG_TO_UITHREAD_OPEN:
            {
                _delegate->onOpen(this);
            }
                break;
            case WS_MSG_TO_UITHREAD_MESSAGE:
            {
                Data* data = (Data*)msg->obj;
                _delegate->onMessage(this, *data);
                CC_SAFE_DELETE_ARRAY(data->bytes);
                CC_SAFE_DELETE(data);
            }
                break;
            case WS_MSG_TO_UITHREAD_CLOSE:
            {
                _delegate->onClose(this);
            }
                break;
            case WS_MSG_TO_UITHREAD_ERROR:
            {
                _delegate->onError(this, err);
            }
                break;
            default:
                break;
        }
    }
    
    int WebSocket::onSocketCallback(struct libwebsocket_context *ctx,
                                    struct libwebsocket *wsi,int reason,void *user, void *in, ssize_t len)
    {
        switch (reason)
        {
            case LWS_CALLBACK_DEL_POLL_FD:
            case LWS_CALLBACK_PROTOCOL_DESTROY:
            case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
            {
                WsMessage* msg = nullptr;
                if (reason == LWS_CALLBACK_CLIENT_CONNECTION_ERROR
                    || (reason == LWS_CALLBACK_PROTOCOL_DESTROY && _readyState == State::CONNECTING)
                    || (reason == LWS_CALLBACK_DEL_POLL_FD && _readyState == State::CONNECTING)
                    )
                {
                    _readyState = State::CLOSING;
                }
                else if (reason == LWS_CALLBACK_PROTOCOL_DESTROY && _readyState == State::CLOSING)
                {
                    msg = new (std::nothrow) WsMessage();
                    msg->what = WS_MSG_TO_UITHREAD_ERROR;
                }
                
                if (msg)
                {
                    _wsHelper->sendMessageToUIThread(msg);
                }

#ifdef ANDROID
				LOG("WebSocket::onSocketCallback, client failed ,erro_code = %d",LWS_CALLBACK_CLIENT_CONNECTION_ERROR);
#endif
            }
                break;
            case LWS_CALLBACK_CLIENT_ESTABLISHED:
            {
                WsMessage* msg = new (std::nothrow) WsMessage();
                msg->what = WS_MSG_TO_UITHREAD_OPEN;
                _readyState = State::OPEN;
                
                /*
                 * start the ball rolling,
                 * LWS_CALLBACK_CLIENT_WRITEABLE will come next service
                 */
                libwebsocket_callback_on_writable(ctx, wsi);
                _wsHelper->sendMessageToUIThread(msg);

#ifdef ANDROID
                LOG("WebSocket::onSocketCallback, client is opened !");
#endif
            }
                break;
                
            case LWS_CALLBACK_CLIENT_WRITEABLE:
            {
                std::lock_guard<std::mutex> lk(_wsHelper->_subThreadWsMessageQueueMutex);
                
                std::list<WsMessage*>::iterator iter = _wsHelper->_subThreadWsMessageQueue->begin();
                
                int bytesWrite = 0;
                for (; iter != _wsHelper->_subThreadWsMessageQueue->end();)
                {
                    WsMessage* subThreadMsg = *iter;
                    
                    if ( WS_MSG_TO_SUBTRHEAD_SENDING_STRING == subThreadMsg->what
                        || WS_MSG_TO_SUBTRHEAD_SENDING_BINARY == subThreadMsg->what)
                    {
                        Data* data = (Data*)subThreadMsg->obj;
                        
                        const size_t c_bufferSize = 2048;
                        
                        size_t remaining = data->len - data->issued;
                        size_t n = std::min(remaining, c_bufferSize );
                        
                        unsigned char* buf = new unsigned char[LWS_SEND_BUFFER_PRE_PADDING + n + LWS_SEND_BUFFER_POST_PADDING];
                        
                        memcpy((char*)&buf[LWS_SEND_BUFFER_PRE_PADDING], data->bytes + data->issued, n);
                        
                        int writeProtocol;
                        
                        if (data->issued == 0)
                        {
                            if (WS_MSG_TO_SUBTRHEAD_SENDING_STRING == subThreadMsg->what)
                            {
                                writeProtocol = LWS_WRITE_TEXT;
                            }
                            else
                            {
                                writeProtocol = LWS_WRITE_BINARY;
                            }
                            
                            // If we have more than 1 fragment
                            if (data->len > c_bufferSize)
                                writeProtocol |= LWS_WRITE_NO_FIN;
                        }
                        else
                        {
                            // we are in the middle of fragments
                            writeProtocol = LWS_WRITE_CONTINUATION;
                            // and if not in the last fragment
                            if (remaining != n)
                                writeProtocol |= LWS_WRITE_NO_FIN;
                        }
                        
                        bytesWrite = libwebsocket_write(wsi,  &buf[LWS_SEND_BUFFER_PRE_PADDING], n, (libwebsocket_write_protocol)writeProtocol);
                        
                        // Buffer overrun?
                        if (bytesWrite < 0)
                        {
                            break;
                        }
                        else if (remaining != n)    //中间分片
                        {
                            data->issued += n;
                            break;
                        }
                        else    //最后分片
                        {
                            CC_SAFE_DELETE_ARRAY(data->bytes);
                            CC_SAFE_DELETE(data);
                            CC_SAFE_DELETE_ARRAY(buf);
                            _wsHelper->_subThreadWsMessageQueue->erase(iter++);
                            CC_SAFE_DELETE(subThreadMsg);

#ifdef ANDROID
                            LOG("WebSocket::onSocketCallback, client send one message to ws server !");
#endif
//                            printf("wsHelper->_subThreadWsMessageQueue size: %u\n",_wsHelper->_subThreadWsMessageQueue->size());
                            break;
                        }
                    }
                }

                libwebsocket_callback_on_writable(ctx, wsi);
            }
                break;
                
            case LWS_CALLBACK_CLOSED:
            {
                _wsHelper->quitSubThread();
                
                if (_readyState != State::CLOSED)
                {
                    err = ErrorCode::CONNECTION_CLOSED_BY_SERVER;
                    
                    WsMessage* msg = new (std::nothrow) WsMessage();
                    _readyState = State::CLOSED;
                    msg->what = WS_MSG_TO_UITHREAD_ERROR;
                    _wsHelper->sendMessageToUIThread(msg);
                }

#ifdef ANDROID
                LOG("WebSocket::onSocketCallback, client is closed !");
#endif
            }
                break;
                
            case LWS_CALLBACK_CLIENT_RECEIVE:
            {
                if (in && len > 0)
                {
                    if (_currentDataLen == 0)
                    {
                        _currentData = new char[len];
                        memcpy (_currentData, in, len);
                        _currentDataLen = len;
                    }
                    else
                    {
                        char *new_data = new char [_currentDataLen + len];
                        memcpy (new_data, _currentData, _currentDataLen);
                        memcpy (new_data + _currentDataLen, in, len);
                        CC_SAFE_DELETE_ARRAY(_currentData);
                        _currentData = new_data;
                        _currentDataLen = _currentDataLen + len;
                    }
                    
                    _pendingFrameDataLen = libwebsockets_remaining_packet_payload (wsi);
                    
                    if (_pendingFrameDataLen > 0)
                    {
                        
                    }
                    
                    if (_pendingFrameDataLen == 0)
                    {
                        WsMessage* msg = new (std::nothrow) WsMessage();
                        msg->what = WS_MSG_TO_UITHREAD_MESSAGE;
                        
                        char* bytes = nullptr;
                        Data* data = new (std::nothrow) Data();
                        
                        if (lws_frame_is_binary(wsi))
                        {
                            
                            bytes = new char[_currentDataLen];
                            data->isBinary = true;
                        }
                        else
                        {
                            bytes = new char[_currentDataLen+1];
                            bytes[_currentDataLen] = '\0';
                            data->isBinary = false;
                        }
                        
                        memcpy(bytes, _currentData, _currentDataLen);
                        
                        data->bytes = bytes;
                        data->len = _currentDataLen;
                        msg->obj = (void*)data;
                        
                        CC_SAFE_DELETE_ARRAY(_currentData);
                        _currentData = nullptr;
                        _currentDataLen = 0;
                        
                        _wsHelper->sendMessageToUIThread(msg);

#ifdef ANDROID
                        LOG("WebSocket::onSocketCallback, client receive one message from ws server !");
#endif
                    }
                }
            }
                break;
            default:
                break;
        }
        
        return 0;
    }
}
