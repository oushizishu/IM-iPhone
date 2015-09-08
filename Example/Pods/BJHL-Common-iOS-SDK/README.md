# BJHL-Common-iOS-SDK 百家 iOS 平台公共库

## Installation

BJHL-Common-iOS-SDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BJHL-Common-iOS-SDK"
```

## Detail 各工具类介绍

- BJCommonDefines
*定义开发中常用到的宏*

``` c
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define SYSTEM_VERSION_EQUAL_OR_MORE_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

// 两种 weakself 写法
#define __WeakSelf__  __weak typeof (self)

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;


#define __WeakObject(object) __weak typeof (object)

#define weakifyself __WeakSelf__ wSelf = self;
#define strongifyself __WeakSelf__ self = wSelf;

#define weakifyobject(obj) __WeakObject(obj) $##obj = obj;
#define strongifobject(obj) __WeakObject(obj) obj = $##obj;
```

- BJCommonProxy 
*Common 库的统一代理类。可通过 Proxy 获得各工具类的实例.*

```Objective-C
  /**
   *  网络模块
   */
  @property (nonatomic, strong, readonly) BJNetworkUtil *networkUtil;
  /**
   *  文件缓存模块
   */
  @property (nonatomic, strong, readonly) BJCacheManagerTool *fileCacheManager;
```

- BJAction 
*仿 Jockey 的一个 Action 监听工具。 通过监听不同 schema, 解析 schema 的 protocol， host， path， parameters。响应初始化时注册的 action.*

```Objective-c
+ (instancetype)shareInstance;
//监听event
- (void)on:(NSString*)event perform:(BJActionHandler)handler;
- (void)off:(NSString *)event;

- (BOOL)sendTotarget:(id)target handleWithUrl:(NSURL*)url;
```

- BJPhotoBrowser *仿微信的图片浏览工具*

> 查看 BJPictureBrowser 类 

- FileCache *文件缓存工具包*

 BJFileCacheManagerTool : 获取沙盒下各个目录的全路径, 以及缓存文件的全部打下 

- ImageView 包
  正对阿里云图片做的 Category。
  
```Objective-c

//如果使用的autolayout，viewDidLoad的时候imageView还没有frame，这时候不能使用这个方法，必须手动传size进去
- (void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

- (void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder size:(CGSize)size;

//cut为true，则短边优先进行裁剪； 否则，按长边优先，其他地方留白
-(void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder size:(CGSize)size cut:(BOOL)cut;
```


- JLPermission *权限判断工具包*
判断当前 APP 是否拥有各项权限。如：日历、相机、联系人、位置、麦克风、通知、相册等；

- MediaRecorder
*语音播放 & 录音功能*

- NetWork
*网络请求*

**BJNetworkUtil** 核心工具类。 传入网络请求参数，返回回调。 具体请求细节由内部处理

- SSKeychain
*获取 UUID*

- UIView *UIView 的扩展 Category*
1. UIScrollView
2. UIView 

- utils 工具包
1. BJTimer
2. NSDate
3. NSDateFormate
4. NSString+MD5
5. NSURL 解析
6. UIColor
7. UIDevice

- view 自定义的 view 包
1. UIAlertView + block

## Author

YangLei-bjhl, jxyl9010@gmail.com

## License

BJHL-Common-iOS-SDK is available under the MIT license. See the LICENSE file for more info.
