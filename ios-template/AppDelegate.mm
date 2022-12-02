#import "AppDelegate.h"
#import "ViewController.h"
#import <EgretNativeIOS.h>
#import "VersionManager.h"
#import "BundleManager.h"

// NSString* _gameUrl = @"http://tool.egret-labs.org/Weiduan/game/index.html";
NSString* _launchUrl = @"http://192.168.33.81/by-fish/bundle/launch.html";
NSString* _gameUrl = @"http://192.168.33.81/by-fish/bundle/index.html";
NSString* _preloadPath = @"/resourse/";
NSString* _remoteVersionURL = @"http://192.168.33.81/by-fish/bundle/version.json";
NSString* _remotePath = @"http://192.168.33.81/by-fish/bundle";

@implementation AppDelegate {
    EgretNativeIOS* _native;
    UIViewController* _viewController;

	VersionManager* _vm;
	BundleManager*	_bm;
	bool _gameStarted;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
	_gameStarted = false;
    _native = [[EgretNativeIOS alloc] init];
    _native.config.showFPS = false;
    _native.config.fpsLogTime = 30;
    _native.config.disableNativeRender = false;
    _native.config.clearCache = false;
    _native.config.useCutout = false;

     _viewController = [[ViewController alloc] initWithEAGLView:[_native createEAGLView]];
    if (![_native initWithViewController:_viewController]) {
        return false;
    }
    
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    _preloadPath = [docDir stringByAppendingString:_preloadPath];
	_preloadPath = [_preloadPath stringByAppendingString:[BundleManager getFileDirByUrl:_remotePath]];
    _native.config.preloadPath = _preloadPath;
	NSLog(@"_preloadPath : %@", _preloadPath);

    _vm = [[VersionManager alloc] init];
	_bm = [[BundleManager alloc] initWithPath:_preloadPath versionMgr:_vm];
	
    [self setLaunchExternalInterfaces];
    
    [_native startGame:_launchUrl];
    
    return true;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	if (_gameStarted) {
        [_native pause];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if (_gameStarted) {
        [_native resume];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
}

- (void)setLaunchExternalInterfaces {
    __block EgretNativeIOS* support = _native;
    [_native setExternalInterface:@"sendToNative" Callback:^(NSString* message) {
        NSString* str = [NSString stringWithFormat:@"Native get message: %@", message];
        NSLog(@"%@", str);
        [support callExternalInterface:@"sendToJS" Value:str];
    }];

	NSString* networkState = [_native getNetworkState];
    if ([networkState isEqualToString:@"NotReachable"]) {
        __block EgretNativeIOS* native = _native;
        [native callExternalInterface:@"APPEVENT_CONNECT_BUNDLE_SERVER_FAIL" Value:@"Network not reachable"];
    }
    // 去除 Block 引用循環
    __block AppDelegate* appBlock = self;
	[_native setExternalInterface:@"APPEVENT_NOTIFY_VERSION" Callback:^(NSString *version) {
        NSLog(@"Get APPEVENT_NOTIFY_VERSION: %@", version);
        // 撈取遠端 Bundle 版本表
        [appBlock->_vm downloadRemoteVersion:_remoteVersionURL success:^{
            // 讀取本地 Bundle 版本表
            Boolean flag = [appBlock->_vm read];
			if (!flag) {
				[appBlock->_vm save:nil];
			}
            if ([appBlock->_vm canUpdateSystem]) {
                NSLog(@"系統可更新");
                NSArray *bundles = [appBlock->_vm getBundleArray:@"app"];
				[appBlock->_bm upgrade:@"app" bundles:bundles success:^{
					NSLog(@"主 Bundle 更新完成");
                    [appBlock enterMainForBlock];
				}];
            }
            else {
                NSLog(@"version : %@ 系統已是最新", version);
                [appBlock enterMainForBlock];
            }
        }];		
    }];
}

-(void) enterMainForBlock {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enterMain];
    });
}

- (void)setExternalInterfaces {
    __block EgretNativeIOS* support = _native;
    [_native setExternalInterface:@"sendToNative" Callback:^(NSString* message) {
        NSString* str = [NSString stringWithFormat:@"Native get message: %@", message];
        NSLog(@"%@", str);
        [support callExternalInterface:@"sendToJS" Value:str];
    }];
    [_native setExternalInterface:@"@onState" Callback:^(NSString *message) {
        NSLog(@"Get @onState: %@", message);
    }];
    [_native setExternalInterface:@"@onError" Callback:^(NSString *message) {
        NSLog(@"Get @onError: %@", message);
    }];
    [_native setExternalInterface:@"@onJSError" Callback:^(NSString *message) {
        NSLog(@"Get @onJSError: %@", message);
    }];
	// 去除 Block 引用循環
    __block AppDelegate* app = self;
	[_native setExternalInterface:@"APPEVENT_CLICK_ENTER_GAME_HALL" Callback:^(NSString *bundleName) {
        NSLog(@"Get APPEVENT_CLICK_ENTER_GAME_HALL: %@", bundleName);

        NSMutableArray *bundles = [app->_vm getBundleArray:bundleName];
        [app->_bm upgrade:bundleName bundles:bundles success:^{
            [app onBundleUpgraded:bundleName];
        }];
    }];
}

- (void)onBundleUpgraded:(NSString*)name {
	[_native callExternalInterface:@"APPEVENT_GAME_UPDATED" Value:name];
}


- (void) enterMain {
    NSLog(@"this is enterMain");
    [_native destroy];
    _native = nil;
    _viewController = nil;

    _native = [[EgretNativeIOS alloc] init];
    _native.config.showFPS = false;
    _native.config.fpsLogTime = 30;
    _native.config.disableNativeRender = false;
    _native.config.clearCache = false;
    _native.config.useCutout = false;
    
    _viewController = [[ViewController alloc] initWithEAGLView:[_native createEAGLView]];
    if (![_native initWithViewController:_viewController]) {
        return;
    }
	_native.config.preloadPath = _preloadPath;
	NSLog(@"_preloadPath : %@", _preloadPath);
    
    [self setExternalInterfaces];
    [_native startGame:_gameUrl];
	_gameStarted = true;
}

- (void)dealloc {
    [_native destroy];
}

@end
