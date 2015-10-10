//
//  define.h
//  libwebsockets
//
//  Created by liwenfeng on 15/5/16.
//
//

#ifndef libwebsockets_define_h
#define libwebsockets_define_h

#define CC_SAFE_DELETE(p)           do { delete (p); (p) = nullptr; } while(0)
#define CC_SAFE_DELETE_ARRAY(p)     do { if(p) { delete[] (p); (p) = nullptr; } } while(0)
#define CC_SAFE_FREE(p)             do { if(p) { free(p); (p) = nullptr; } } while(0)
#define CC_SAFE_RELEASE(p)          do { if(p) { (p)->release(); } } while(0)
#define CC_SAFE_RELEASE_NULL(p)     do { if(p) { (p)->release(); (p) = nullptr; } } while(0)
#define CC_SAFE_RETAIN(p)           do { if(p) { (p)->retain(); } } while(0)

namespace network {
    
    class WsMessage
    {
    public:
        WsMessage()
        : what(0)
        ,obj(NULL){}
        unsigned int what; // message type
        void* obj;
    };
    
    enum WS_MSG {
        WS_MSG_TO_SUBTRHEAD_SENDING_STRING = 0,
        WS_MSG_TO_SUBTRHEAD_SENDING_BINARY,
        WS_MSG_TO_UITHREAD_OPEN,
        WS_MSG_TO_UITHREAD_MESSAGE,
        WS_MSG_TO_UITHREAD_ERROR,
        WS_MSG_TO_UITHREAD_CLOSE
    };
    
    /**
     *  State enum used to represent the Websocket state.
     */
    enum class State
    {
        CONNECTING,     //默认状态，还未连上ws server
        OPEN,           //与server建立完链接
        CLOSING,
        CLOSED,         //如果是主动close的话，会在libwebsocket_context_destroy后
    };
    /**
     * Data structure for message
     */
    struct Data
    {
        Data():bytes(nullptr), len(0), issued(0), isBinary(false){}
        char* bytes;
        ssize_t len;
        ssize_t issued; //已发送的bytes数目
        bool isBinary;
    };
    
    /**
     * ErrorCode enum used to represent the error in the websocket.
     */
    enum class ErrorCode
    {
        TIME_OUT,
        CONNECTION_FAILURE,
        UNKNOWN,
    };
}
#endif
