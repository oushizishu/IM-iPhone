LIB_WEBSOCKETS_INC="../../../libwebsockets/include"
LIB_WEBSOCKETS_LIB="../../../libwebsockets/lib"

CFLAGS  += -I$(LIB_WEBSOCKETS_INC)
LDFLAGS += -fpic -shared 

SOURCES = $(wildcard WebSocket/*.cpp)
OBJS    = $(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(patsubst %.m,%.o,$(SOURCES))))
TARGET_LIB := libwebsocketclient.a

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@ $(GTKFLAGS)
%.o:%.cpp
	$(CXX) $(CFLAGS) -c $< -o $@ $(GTKFLAGS)
%.o:%.m
	$(CXX) $(CFLAGS) $(LDCFLAGS) -c $< -o $@ $(GTKFLAGS)

all:$(TARGET_LIB)
$(TARGET_LIB) : $(OBJS)
	@echo "AR    $@"	
	#$(AR) rcs $@ $(OBJS) $(BOOST_LIBS)
	libtool $(OBJS) -static -arch_only $(ARCH_TARGET) -L$(LIB_WEBSOCKETS_LIB) -lwebsockets -o libwebsocketclient.a
	@echo "RANLIB    $@"
	$(RANLIB)   $@

clean:
	rm -rf $(OBJS)
	rm -rf *.o $(TARGET_LIB) $(TARGET)
